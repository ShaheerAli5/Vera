import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/home/presentation/pages/home_screen.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/realtime/moment_realtime_service.dart';
import 'package:vera/core/realtime/moment_realtime_route.dart';
import 'package:vera/features/home/presentation/utils/for_you_live_refresh.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

class FeedHarness extends StatefulWidget {
  const FeedHarness({super.key, required this.active, required this.refresh});
  final bool active;
  final Future<void> Function() refresh;
  @override
  State<FeedHarness> createState() => _FeedHarnessState();
}

class _FeedHarnessState extends State<FeedHarness>
    with ForYouLiveRefresh<FeedHarness> {
  @override
  bool get forYouRefreshActive => widget.active;
  @override
  Future<void> loadForYouData({required bool showLoading}) => widget.refresh();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Feed'));
}

void main() {
  test(
    'feed demand reconnects with latest token and releases shared socket safely',
    () {
      final sockets = <FakeMomentSocket>[];
      final auth = <dynamic>[];
      final service = MomentRealtimeService(
        baseUrl: 'https://example.com',
        token: 'old',
        socketFactory: (_, options) {
          auth.add(options['auth']);
          final socket = FakeMomentSocket();
          sockets.add(socket);
          return socket;
        },
      );
      addTearDown(service.dispose);
      final changes = <String>[];
      service.forYouChanges.listen(changes.add);
      service.subscribeForYou();
      service.subscribeForYou();
      sockets.single.receive('connect');
      expect(sockets.single.emissions.single.$1, 'home:for-you:subscribe');
      sockets.single.receive('home:for-you:changed', {
        'reason': 'PUBLIC_MOMENT_PUBLISHED',
      });
      sockets.single.receive('home:for-you:changed', {
        'reason': 'PRIVATE_MOMENT_APPROVED',
      });
      expect(changes, ['PUBLIC_MOMENT_PUBLISHED']);
      final old = sockets.single;
      service.updateToken('new');
      expect(old.disposed, isTrue);
      expect(auth.last, {'token': 'new'});
      old.receive('home:for-you:changed', {'reason': 'PUBLIC_MOMENT_REMOVED'});
      expect(changes.length, 1);
      final socket = sockets.last;
      socket.receive('connect');
      socket.receive('connect');
      expect(
        socket.emissions.where((e) => e.$1 == 'home:for-you:subscribe').length,
        2,
      );
      service.watch('post');
      service.unsubscribeForYou();
      expect(socket.emissions.last.$1, 'moment:watch');
      service.unsubscribeForYou();
      expect(socket.emissions.last.$1, 'home:for-you:unsubscribe');
      expect(socket.disposed, isFalse);
      socket.receive('home:for-you:changed', {
        'reason': 'PUBLIC_MOMENT_REMOVED',
      });
      expect(changes.length, 1);
      service.unwatch('post');
      expect(socket.disposed, isTrue);
    },
  );

  testWidgets(
    'Home refreshes only For You on invalidation and honors empty REST results',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final sockets = <FakeMomentSocket>[];
      final reads = <String, int>{};
      var published = false;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test',
        momentSocketFactory: (_, options) {
          final socket = FakeMomentSocket();
          sockets.add(socket);
          return socket;
        },
        httpClient: MockClient((request) async {
          final key =
              '${request.url.path}?${request.url.queryParameters['tab']}';
          reads[key] = (reads[key] ?? 0) + 1;
          if (request.url.path.endsWith('/profile')) {
            return http.Response('{"id":"reader","displayName":"Reader"}', 200);
          }
          final forYou = request.url.queryParameters['tab'] == 'FOR_YOU';
          return http.Response(
            jsonEncode({
              'items': forYou && published
                  ? [
                      {
                        'id': 'public-post',
                        'visibility': 'PUBLIC',
                        'status': 'PUBLISHED',
                        'creator': {
                          'id': 'creator',
                          'displayName': 'Published Creator',
                        },
                        'hasMedia': false,
                        'contentType': 'TEXT',
                        'availability': {
                          'isApproved': true,
                          'isUnlocked': false,
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
          builder: (_, child) => ApiClientScope(client: client, child: child!),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();
      sockets.last.receive('connect');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final before = Map<String, int>.from(reads);
      published = true;
      sockets.last.receive('home:for-you:changed', {
        'reason': 'PUBLIC_MOMENT_PUBLISHED',
      });
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Published Creator'), findsOneWidget);
      expect(
        reads['/api/v1/home/feed?FOR_YOU'],
        before['/api/v1/home/feed?FOR_YOU']! + 1,
      );
      expect(
        reads['/api/v1/home/feed?YOUR_MOMENTS'],
        before['/api/v1/home/feed?YOUR_MOMENTS'],
      );
      published = false;
      sockets.last.receive('home:for-you:changed', {
        'reason': 'PUBLIC_MOMENT_REMOVED',
      });
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Published Creator'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
    },
  );

  testWidgets(
    'visible feed debounces changes and stops on tab, route and app departure',
    (tester) async {
      final sockets = <FakeMomentSocket>[];
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test',
        momentSocketFactory: (_, options) {
          final socket = FakeMomentSocket();
          sockets.add(socket);
          return socket;
        },
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(client.close);
      var reads = 0;
      var active = true;
      late StateSetter change;
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [momentRouteObserver],
          builder: (_, child) => ApiClientScope(client: client, child: child!),
          home: StatefulBuilder(
            builder: (_, setState) {
              change = setState;
              return FeedHarness(
                active: active,
                refresh: () async {
                  reads++;
                },
              );
            },
          ),
        ),
      );
      sockets.last.receive('connect');
      await tester.pump(const Duration(milliseconds: 300));
      expect(reads, 1);
      for (var i = 0; i < 5; i++) {
        sockets.last.receive('home:for-you:changed', {
          'reason': 'PUBLIC_MOMENT_PUBLISHED',
        });
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(reads, 2);
      final old = sockets.last;
      change(() => active = false);
      await tester.pump();
      expect(old.emissions.last.$1, 'home:for-you:unsubscribe');
      change(() => active = true);
      await tester.pump();
      sockets.last.receive('connect');
      await tester.pump(const Duration(milliseconds: 300));
      expect(reads, 3);
      final routeSocket = sockets.last;
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      expect(routeSocket.emissions.last.$1, 'home:for-you:unsubscribe');
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      sockets.last.receive('connect');
      await tester.pump(const Duration(milliseconds: 300));
      final backgroundSocket = sockets.last;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(backgroundSocket.emissions.last.$1, 'home:for-you:unsubscribe');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      sockets.last.receive('connect');
      await tester.pump(const Duration(milliseconds: 300));
      final lastSocket = sockets.last;
      await tester.pumpWidget(const SizedBox.shrink());
      expect(lastSocket.emissions.last.$1, 'home:for-you:unsubscribe');
      expect(lastSocket.disposed, isTrue);
    },
  );
}
