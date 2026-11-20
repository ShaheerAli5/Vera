import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/network/api_exception.dart';
import 'package:vera/core/realtime/moment_realtime_route.dart';
import 'package:vera/core/realtime/moment_realtime_service.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/home/data/datasources/moments_remote_data_source.dart';
import 'package:vera/features/home/data/models/moment_model.dart';
import 'package:vera/features/home/domain/entities/moment.dart';
import 'package:vera/features/home/presentation/pages/locked_moment_screen.dart';
import 'package:vera/features/home/presentation/pages/unlocked_moment_screen.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final invite in ['PENDING', 'DECLINED', 'ACCEPTED']) {
    test('$invite invitation gates server unlocked state', () {
      final moment = MomentModel.fromJson({
        'id': 'post',
        'invitationStatus': invite,
        'isUnlocked': true,
        'availability': {'isApproved': true},
      }).toEntity();
      expect(moment.canAccessContent, invite == 'ACCEPTED');
    });
  }
  test('a past schedule without server unlock confirmation stays locked', () {
    final moment = MomentModel.fromJson({
      'id': 'post',
      'invitationStatus': 'ACCEPTED',
      'unlockRule': {'type': 'DATE', 'unlockAt': '2000-01-01T00:00:00Z'},
    }).toEntity();
    expect(moment.canAccessContent, isFalse);
  });
  test(
    'accepted server timestamp confirms access, but explicit false overrides it',
    () {
      final json = <String, dynamic>{
        'id': 'post',
        'invitationStatus': 'ACCEPTED',
        'unlockedAt': '2000-01-01T00:00:00Z',
      };
      expect(MomentModel.fromJson(json).toEntity().canAccessContent, isTrue);
      expect(
        MomentModel.fromJson({
          ...json,
          'isUnlocked': false,
        }).toEntity().canAccessContent,
        isFalse,
      );
      expect(
        MomentModel.fromJson({
          ...json,
          'availability': {'isApproved': false, 'isUnlocked': true},
        }).toEntity().canAccessContent,
        isFalse,
      );
    },
  );
  test(
    'REST can advance older socket state while newer socket events win races',
    () {
      final socket = FakeMomentSocket();
      final service = MomentRealtimeService(
        baseUrl: 'https://example.com',
        token: 'test',
        socketFactory: (_, options) => socket,
      );
      addTearDown(service.dispose);
      service.watch('post');
      const moment = Moment(
        id: 'post',
        userName: '',
        userAvatarUrl: '',
        timeAgo: '',
        backgroundImageUrl: '',
        unlockCondition: '',
        invitationStatus: 'ACCEPTED',
      );
      socket.receive('moment:status', {
        'momentId': 'post',
        'availability': {'isApproved': true, 'isUnlocked': false},
      });
      final before = service.latest('post');
      expect(
        service
            .reconcileRest(moment.copyWith(isReadyToOpen: true), before)
            .canAccessContent,
        isTrue,
      );
      final nextBefore = service.latest('post');
      socket.receive('moment:status', {
        'momentId': 'post',
        'availability': {'isUnlocked': false},
      });
      expect(
        service
            .reconcileRest(moment.copyWith(isReadyToOpen: true), nextBefore)
            .canAccessContent,
        isFalse,
      );
    },
  );
  test(
    'acceptance supersedes overlapping inbox reads but honors newer socket events',
    () {
      final socket = FakeMomentSocket();
      final service = MomentRealtimeService(
        baseUrl: 'https://example.com',
        token: 'test',
        socketFactory: (_, options) => socket,
      );
      addTearDown(service.dispose);
      service.watch('post');
      const pending = Moment(
        id: 'post',
        userName: '',
        userAvatarUrl: '',
        timeAgo: '',
        backgroundImageUrl: '',
        unlockCondition: '',
        invitationStatus: 'PENDING',
      );
      final before = service.latest('post');
      service.reconcileRest(pending, before);
      final accepted = pending.copyWith(
        invitationStatus: 'ACCEPTED',
        isReadyToOpen: true,
      );
      expect(
        service
            .reconcileRest(accepted, before, mutation: true)
            .canAccessContent,
        isTrue,
      );
      final nextBefore = service.latest('post');
      socket.receive('moment:status', {
        'momentId': 'post',
        'availability': {'isUnlocked': false},
      });
      expect(
        service
            .reconcileRest(accepted, nextBefore, mutation: true)
            .canAccessContent,
        isFalse,
      );
    },
  );

  test(
    'invitation and protected content requests use bearer auth and exact endpoints',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test',
        httpClient: MockClient((request) async {
          requests.add(request);
          expect(request.headers['Authorization'], 'Bearer test');
          if (request.url.path.endsWith('/content/media'))
            return http.Response.bytes([1, 2, 3], 200);
          return http.Response('{"id":"post","isUnlocked":true}', 200);
        }),
      );
      addTearDown(client.close);
      final source = MomentsRemoteDataSource(client);
      await source.acceptInvitation('post');
      await source.declineInvitation('post');
      await source.getMomentContent('post');
      await source.getMomentMedia('post');
      expect(requests.map((r) => r.url.path), [
        '/api/v1/moments/post/invitations/accept',
        '/api/v1/moments/post/invitations/decline',
        '/api/v1/moments/post/content',
        '/api/v1/moments/post/content/media',
      ]);
      expect(requests.take(2).every((r) => r.body.isEmpty), isTrue);
      expect(
        source.getMomentMediaStreamUrl('post'),
        endsWith('/content/media'),
      );
    },
  );
  test('inbox status fallback finds a moment beyond the first page', () async {
    final pages = <String>[];
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      initialAuthToken: 'test',
      httpClient: MockClient((request) async {
        pages.add(request.url.queryParameters['page']!);
        expect(request.url.path, '/api/v1/moments/inbox');
        expect(request.url.queryParameters['limit'], '20');
        final first = pages.length == 1;
        return http.Response(
          jsonEncode({
            'items': [
              {'id': first ? 'other' : 'post'},
            ],
            'meta': {'hasMore': first},
          }),
          200,
        );
      }),
    );
    addTearDown(client.close);
    expect(
      (await MomentsRemoteDataSource(client).getInboxMomentById('post'))?.id,
      'post',
    );
    expect(pages, ['1', '2']);
  });
  test('stale location proof never reaches the backend', () async {
    var requests = 0;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      httpClient: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);
    await expectLater(
      MomentsRemoteDataSource(client).unlockMoment(
        momentId: 'post',
        latitude: 24.8,
        longitude: 67.1,
        accuracyM: 8.54321,
        capturedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        isMocked: false,
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          'stale_location_proof',
        ),
      ),
    );
    expect(requests, 0);
  });

  testWidgets(
    'unconfirmed unlocked-screen entry cannot fetch protected content',
    (tester) async {
      final paths = <String>[];
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test',
        momentSocketFactory: (_, options) => FakeMomentSocket(),
        httpClient: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response('{"id":"reader","displayName":"Reader"}', 200);
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [momentRouteObserver],
          builder: (context, child) =>
              ApiClientScope(client: client, child: child!),
          home: const UnlockedMomentScreen(
            moment: Moment(
              id: 'post',
              userName: 'Author',
              userAvatarUrl: '',
              timeAgo: '',
              backgroundImageUrl: '',
              unlockCondition: '',
              invitationStatus: 'PENDING',
              isReadyToOpen: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LockedMomentScreen), findsOneWidget);
      expect(paths.any((path) => path.contains('/content')), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
    },
  );

  for (final lateAcceptance in [false, true]) {
    testWidgets(
      'pending invitation accepts into ${lateAcceptance ? 'unlocked' : 'locked'} state',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var unlockCalls = 0;
        var contentCalls = 0;
        final client = ApiClient(
          config: const AppConfig(apiBaseUrl: 'https://example.com'),
          initialAuthToken: 'test',
          momentSocketFactory: (_, options) => FakeMomentSocket(),
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/profile'))
              return http.Response(
                '{"id":"reader","displayName":"Reader"}',
                200,
              );
            if (request.url.path.endsWith('/unlock')) unlockCalls++;
            if (request.url.path.endsWith('/content')) contentCalls++;
            if (request.url.path.endsWith('/invitations/accept')) {
              expect(request.body, isEmpty);
              return http.Response(
                jsonEncode({
                  'id': 'post',
                  'invitationStatus': 'ACCEPTED',
                  'unlockedAt': lateAcceptance ? '2000-01-01T00:00:00Z' : null,
                }),
                201,
              );
            }
            return http.Response(
              '{"id":"post","hasMedia":false,"contentType":"TEXT","message":"Protected text","items":[]}',
              200,
            );
          }),
        );
        addTearDown(client.close);
        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [momentRouteObserver],
            builder: (context, child) =>
                ApiClientScope(client: client, child: child!),
            home: LockedMomentScreen(
              moment: Moment(
                id: 'post',
                creatorId: 'author',
                userName: 'Author',
                userAvatarUrl: '',
                timeAgo: '',
                backgroundImageUrl: 'https://static.invalid/private.jpg',
                unlockCondition: 'Scheduled',
                unlockType: MomentUnlockType.time,
                unlockAt: DateTime(2000),
                status: 'PUBLISHED',
                invitationStatus: 'PENDING',
                isApproved: true,
                hasMedia: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final check = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Accept the invitation first'),
        );
        expect(check.onPressed, isNull);
        expect(contentCalls, 0);
        await tester.ensureVisible(find.text('Accept'));
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();
        expect(unlockCalls, 0, reason: 'DATE acceptance never POSTs unlock');
        if (lateAcceptance) {
          expect(find.byType(UnlockedMomentScreen), findsOneWidget);
          expect(contentCalls, greaterThan(0));
        } else {
          expect(find.byType(LockedMomentScreen), findsOneWidget);
          expect(contentCalls, 0);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        ServerTimeManager.instance.dispose();
      },
    );
  }
}
