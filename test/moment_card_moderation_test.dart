import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/realtime/moment_realtime_route.dart';
import 'package:vera/core/realtime/moment_realtime_service.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/home/data/models/moment_model.dart';
import 'package:vera/features/home/domain/entities/moment.dart';
import 'package:vera/features/home/presentation/pages/home_screen.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

void main() {
  for (final visibility in ['PUBLIC', 'PRIVATE']) {
    test(
      '$visibility sender badge follows realtime moderation without REST reconstruction',
      () {
        final initial = MomentModel.fromJson({
          'id': 'post',
          'visibility': visibility,
          'status': 'PENDING_REVIEW',
          'unlockRule': {'type': 'DATE', 'unlockAt': '2099-01-01T00:00:00Z'},
        }).toEntity();
        expect(initial.sentBadgeSubtitle, 'Pending review');
        final approved = MomentRealtimeUpdate.parse('moment:approved', {
          'momentId': 'post',
          'availability': {'isApproved': true, 'isUnlocked': false},
        })!.apply(initial);
        expect(approved.status, 'PUBLISHED');
        expect(approved.sentBadgeSubtitle, 'Published');
        expect(approved.canAccessContent, isFalse);
        final rejected = MomentRealtimeUpdate.parse('moment:rejected', {
          'momentId': 'post',
          'availability': {'isApproved': false, 'isUnlocked': false},
        })!.apply(approved);
        expect(rejected.sentBadgeSubtitle, 'Rejected');
        expect(rejected.canAccessContent, isFalse);
        expect(
          rejected.copyWith(status: 'PENDING_REVIEW').sentBadgeSubtitle,
          'Pending review',
        );
      },
    );
  }
  test(
    'invitation subtitles and fallback text retain their existing meaning',
    () {
      const moment = Moment(
        id: 'post',
        userName: '',
        userAvatarUrl: '',
        timeAgo: '',
        backgroundImageUrl: '',
        unlockCondition: '',
        status: 'PENDING_REVIEW',
        invitationStatus: 'PENDING',
      );
      expect(moment.sentBadgeSubtitle, 'Pending invitation');
      expect(
        moment
            .copyWith(invitationStatus: 'ACCEPTED', status: 'PUBLISHED')
            .sentBadgeSubtitle,
        'Invitation accepted',
      );
      expect(
        moment.copyWith(invitationStatus: 'DECLINED').sentBadgeSubtitle,
        'Invitation declined',
      );
    },
  );

  testWidgets(
    'Your Moments card changes Pending review to Published and Rejected without opening it',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final sockets = <FakeMomentSocket>[];
      final requests = <String>[];
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test',
        momentSocketFactory: (_, options) {
          final socket = FakeMomentSocket();
          sockets.add(socket);
          return socket;
        },
        httpClient: MockClient((request) async {
          requests.add(request.url.path);
          if (request.url.path.endsWith('/profile')) {
            return http.Response('{"id":"author","displayName":"Author"}', 200);
          }
          final ownFeed =
              request.url.path.endsWith('/home/feed') &&
              request.url.queryParameters['tab'] == 'YOUR_MOMENTS';
          return http.Response(
            jsonEncode({
              'items': ownFeed
                  ? [
                      {
                        'id': 'post',
                        'creatorId': 'author',
                        'title': 'Public scheduled moment',
                        'visibility': 'PUBLIC',
                        'status': 'PENDING_REVIEW',
                        'contentType': 'TEXT',
                        'hasMedia': false,
                        'unlockRule': {
                          'type': 'DATE',
                          'unlockAt': '2099-01-01T00:00:00Z',
                        },
                      },
                    ]
                  : [],
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      await client.setTokens(userRole: 'user');
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [momentRouteObserver],
          builder: (context, child) =>
              ApiClientScope(client: client, child: child!),
          home: const HomeScreen(initialTabIndex: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
      final socket = sockets.last;
      socket.receive('connect');
      await tester.pumpAndSettle();
      await tester.pump();
      final before = requests.length;
      socket.receive('moment:approved', {
        'momentId': 'post',
        'availability': {'isApproved': true, 'isUnlocked': false},
      });
      await tester.pumpAndSettle();
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Pending review'), findsNothing);
      expect(find.byKey(const ValueKey('moment-card-locked')), findsOneWidget);
      socket.receive('moment:rejected', {
        'momentId': 'post',
        'availability': {'isApproved': false, 'isUnlocked': false},
      });
      await tester.pumpAndSettle();
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Published'), findsNothing);
      expect(
        requests.length,
        before,
        reason:
            'The card updates from socket state without an API refresh or navigation',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
    },
  );
}
