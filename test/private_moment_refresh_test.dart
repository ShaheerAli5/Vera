import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/realtime/moment_realtime_route.dart';
import 'package:vera/core/services/push_notification_service.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/home/presentation/pages/home_screen.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

void main() {
  testWidgets(
    'countdown refreshes inbox without unlocking; reconnect and push refresh again',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final sockets = <FakeMomentSocket>[];
      var inboxReads = 0;
      final methods = <String>[];
      var unlocked = false;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test',
        momentSocketFactory: (_, options) {
          final socket = FakeMomentSocket();
          sockets.add(socket);
          return socket;
        },
        httpClient: MockClient((request) async {
          methods.add(request.method);
          if (request.url.path.endsWith('/profile'))
            return http.Response('{"id":"reader","displayName":"Reader"}', 200);
          if (request.url.path.endsWith('/inbox')) inboxReads++;
          final items = request.url.path.contains('/chat/')
              ? []
              : [
                  {
                    'id': 'post',
                    'creatorId': 'author',
                    'title': 'Private post',
                    'contentType': 'TEXT',
                    'hasMedia': false,
                    'invitationStatus': 'ACCEPTED',
                    'isUnlocked': unlocked,
                    'availability': {
                      'isApproved': true,
                      'isUnlocked': unlocked,
                    },
                    'unlockRule': {
                      'type': 'DATE',
                      'unlockAt': '2000-01-01T00:00:00Z',
                    },
                  },
                ];
          return http.Response(jsonEncode({'items': items}), 200);
        }),
      );
      addTearDown(client.close);
      await client.setTokens(userRole: 'user');
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [momentRouteObserver],
          builder: (context, child) =>
              ApiClientScope(client: client, child: child!),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(inboxReads, 1);
      final firstReads = inboxReads;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(inboxReads, greaterThan(firstReads));
      expect(find.byKey(const ValueKey('moment-card-locked')), findsOneWidget);
      expect(find.byKey(const ValueKey('moment-card-unlocked')), findsNothing);
      final beforeReconnect = inboxReads;
      sockets.last.receive('connect');
      await tester.pumpAndSettle();
      expect(inboxReads, greaterThan(beforeReconnect));
      sockets.last.receive('connect');
      await tester.pumpAndSettle();
      final beforePush = inboxReads;
      unlocked = true;
      PushNotificationService.instance.latestForegroundMessage.value =
          const RemoteMessage(messageId: 'unlock-push');
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(inboxReads, greaterThan(beforePush));
      expect(find.byKey(const ValueKey('moment-card-unlocked')), findsOneWidget);
      expect(methods.every((method) => method == 'GET'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      PushNotificationService.instance.latestForegroundMessage.value = null;
      ServerTimeManager.instance.dispose();
    },
  );
}
