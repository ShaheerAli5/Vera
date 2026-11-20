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
import 'package:vera/features/home/presentation/pages/home_screen.dart';
import 'package:vera/features/home/presentation/pages/unlocked_moment_screen.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => ServerTimeManager.instance.dispose());

  for (final status in ['DRAFT', 'PENDING_REVIEW', 'PUBLISHED', 'REJECTED']) {
    test('server preview permits creator content while preserving $status', () {
      final moment = MomentModel.fromJson({
        'id': 'own', 'status': status,
        'canPreview': true, 'isUnlocked': true,
        'viewer': {'isCreator': true, 'canPreview': true, 'isUnlocked': true},
        'availability': {'isApproved': false, 'isUnlocked': false},
        'unlock': {'type': 'DATE', 'unlockAt': '2099-01-01T00:00:00Z'},
      }).toEntity();
      expect(moment.canPreview, isTrue);
      expect(moment.canAccessContent, isTrue);
      expect(moment.status, status);
      final update = MomentRealtimeUpdate.parse('moment:rejected', {
        'momentId': 'own', 'availability': {'isApproved': false, 'isUnlocked': false},
      })!;
      expect(update.apply(moment).canAccessContent, isTrue);
      final deleted = MomentRealtimeUpdate.parse('moment:deleted', {'momentId': 'own'})!;
      expect(deleted.apply(moment).canAccessContent, isFalse);
    });
  }

  test('preview must be explicit; recipients cannot bypass approval, invitation or dates', () {
    for (final status in ['PENDING_REVIEW', 'REJECTED']) {
      final recipient = MomentModel.fromJson({
        'id': 'received', 'status': status,
        'isUnlocked': true, 'unlockedAt': '2000-01-01T00:00:00Z',
      }).toEntity();
      expect(recipient.canAccessContent, isFalse);
    }
    final recipient = MomentModel.fromJson({
      'id': 'received', 'status': 'PUBLISHED', 'invitationStatus': 'PENDING',
      'viewer': {'isUnlocked': true},
    }).toEntity();
    expect(recipient.canAccessContent, isFalse);
    final due = MomentModel.fromJson({
      'id': 'received', 'status': 'PUBLISHED',
      'unlock': {'type': 'DATE', 'unlockAt': '2000-01-01T00:00:00Z'},
    }).toEntity();
    expect(due.canAccessContent, isFalse);
    final owner = MomentModel.fromJson({
      'id': 'own', 'status': 'PUBLISHED', 'viewer': {'canPreview': true},
    }).toEntity();
    final revoked = MomentRealtimeUpdate.parse('moment:status', {
      'momentId': 'own', 'viewer': {'canPreview': false},
    })!.apply(owner);
    expect(revoked.canAccessContent, isFalse);
    final denied = MomentModel.fromJson({
      'id': 'own', 'status': 'DRAFT', 'canPreview': true,
      'viewer': {'isCreator': true, 'canPreview': false},
    }).toEntity();
    expect(denied.canAccessContent, isFalse);
  });

  testWidgets('Your Moments opens a pending creator preview and retains access on detail refresh', (tester) async {
    tester.view.physicalSize = const Size(600, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    var contentReads = 0;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      momentSocketFactory: (_, options) => FakeMomentSocket(),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/profile')) {
          return http.Response('{"id":"creator","displayName":"Creator","role":"user"}', 200);
        }
        if (request.url.path.endsWith('/content')) {
          contentReads++;
          // Some protected content responses omit the viewer envelope.
          return http.Response('{"id":"own","status":"PENDING_REVIEW","hasMedia":false,"contentType":"TEXT","message":"Creator preview"}', 200);
        }
        return http.Response(jsonEncode({'items': request.url.queryParameters['tab'] == 'YOUR_MOMENTS' ? [{
          'id': 'own', 'status': 'PENDING_REVIEW',
          'visibility': 'PUBLIC', 'contentType': 'TEXT', 'hasMedia': false,
          'creator': {'id': 'creator', 'displayName': 'Creator'},
          'viewer': {'isCreator': true, 'canPreview': true, 'isUnlocked': true},
          'unlockRule': {'type': 'DATE', 'unlockAt': '2099-01-01T00:00:00Z'},
        }] : []}), 200);
      }),
    );
    addTearDown(client.close);
    await client.setTokens(authToken: 'test', userRole: 'user');
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [momentRouteObserver],
      builder: (_, child) => ApiClientScope(client: client, child: child!),
      home: const HomeScreen(initialTabIndex: 2),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('moment-card-unlocked')), findsOneWidget);
    expect(find.text('Pending review'), findsOneWidget);
    await tester.tap(find.text('Ready to open'));
    await tester.pumpAndSettle();
    expect(find.byType(UnlockedMomentScreen), findsOneWidget);
    expect(find.text('Creator preview'), findsOneWidget);
    expect(contentReads, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    ServerTimeManager.instance.dispose();
  });
}
