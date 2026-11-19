import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/realtime/moment_realtime_route.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:vera/features/admin/presentation/pages/admin_moderation_queue_screen.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

class _Tabs extends StatefulWidget {
  const _Tabs();
  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => index = 0),
              child: const Text('Dashboard tab'),
            ),
            TextButton(
              onPressed: () => setState(() => index = 1),
              child: const Text('Queue tab'),
            ),
          ],
        ),
        Expanded(
          child: IndexedStack(
            index: index,
            children: [
              TickerMode(
                enabled: index == 0,
                child: AdminDashboardScreen(isActive: index == 0),
              ),
              TickerMode(
                enabled: index == 1,
                child: AdminModerationQueueScreen(isActive: index == 1),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void main() {
  tearDown(() => ServerTimeManager.instance.dispose());
  testWidgets(
    'admin counts and queue update on activation, socket events, discovery, resume and return',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var pending = true;
      var dashboardReads = 0;
      var queueReads = 0;
      var pendingTotal = 123;
      var includePendingStats = true;
      final sockets = <FakeMomentSocket>[];
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test',
        connectTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        momentSocketFactory: (url, options) {
          final socket = FakeMomentSocket();
          sockets.add(socket);
          return socket;
        },
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/admin/moments') {
            if (request.url.queryParameters['limit'] == '50') {
              dashboardReads++;
            } else {
              queueReads++;
            }
            return http.Response(
              jsonEncode({
                'items': pending
                    ? [
                        {
                          'id': 'post',
                          'title': 'New post',
                          'status': 'PENDING_REVIEW',
                          'contentType': 'TEXT',
                          'hasMedia': false,
                        },
                      ]
                    : [],
                'total': pending ? pendingTotal : 0,
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/stats')) {
            return http.Response(
              jsonEncode({
                if (includePendingStats)
                  'pendingMoments': pending ? pendingTotal : 0,
              }),
              200,
            );
          }
          return http.Response('{"items":[]}', 200);
        }),
      );
      addTearDown(client.close);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [momentRouteObserver],
          builder: (context, child) =>
              ApiClientScope(client: client, child: child!),
          home: const _Tabs(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(
        find.text('123'),
        findsOneWidget,
        reason: 'Use total count, not the loaded page length',
      );
      expect(dashboardReads, 1);
      expect(queueReads, 0, reason: 'Hidden tabs must not fetch');

      await tester.tap(find.text('Queue tab'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Moderation Queue (1)'), findsOneWidget);
      expect(queueReads, 1);
      final socket = sockets.last;
      socket.receive('connect');
      pending = false;
      socket.receive('moment:approved', {
        'momentId': 'post',
        'availability': {'isUnlocked': false},
      });
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Moderation Queue (0)'), findsOneWidget);
      expect(find.text('No moments pending review'), findsOneWidget);

      // The empty queue has no IDs to watch. Discover new submissions by a read.
      pending = true;
      pendingTotal = 1;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(find.text('Moderation Queue (1)'), findsOneWidget);

      final beforePause = queueReads;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(queueReads, beforePause);
      pending = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Moderation Queue (0)'), findsOneWidget);

      await tester.tap(find.text('Dashboard tab'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(dashboardReads, greaterThan(1));
      expect(find.text('123'), findsNothing);

      final beforeCover = dashboardReads;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Review page')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      expect(
        dashboardReads,
        beforeCover,
        reason: 'Covered routes must not poll',
      );
      pending = true;
      pendingTotal = 70;
      includePendingStats = false;
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(
        find.text('70'),
        findsOneWidget,
        reason: 'Fall back to queue total if stats omit pendingMoments',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
    },
  );
  testWidgets(
    'slow queue requests never overlap and retain one follow-up refresh',
    (tester) async {
      final pending = Completer<http.Response>();
      var reads = 0;
      var active = 0;
      var maxActive = 0;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test',
        connectTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        momentSocketFactory: (url, options) => FakeMomentSocket(),
        httpClient: MockClient((request) async {
          reads++;
          active++;
          if (active > maxActive) maxActive = active;
          final response = reads == 1
              ? await pending.future
              : http.Response('{"items":[]}', 200);
          active--;
          return response;
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [momentRouteObserver],
          builder: (context, child) =>
              ApiClientScope(client: client, child: child!),
          home: const Scaffold(body: AdminModerationQueueScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(reads, 1);
      await tester.pump(const Duration(seconds: 31));
      expect(
        reads,
        1,
        reason: 'Automatic refresh must not overlap a pending request',
      );
      pending.complete(http.Response('{"items":[]}', 200));
      await tester.pumpAndSettle();
      expect(
        reads,
        2,
        reason: 'Coalesce multiple invalidations into one follow-up',
      );
      expect(maxActive, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
    },
  );
}
