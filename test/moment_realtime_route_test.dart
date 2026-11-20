import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/realtime/moment_realtime_route.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/home/domain/entities/moment.dart';
import 'package:vera/features/home/presentation/pages/locked_moment_screen.dart';
import 'package:vera/features/home/presentation/pages/unlocked_moment_screen.dart';
import 'package:vera/features/home/presentation/widgets/moment_card.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

void main() {
  testWidgets('cards obey availability and release the old ID when reused', (
    tester,
  ) async {
    final sockets = <FakeMomentSocket>[];
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://vera.aptechmedia.com'),
      initialAuthToken: 'test',
      momentSocketFactory: (url, options) {
        final socket = FakeMomentSocket();
        sockets.add(socket);
        return socket;
      },
      httpClient: MockClient(
        (request) async =>
            http.Response('{"id":"reader","displayName":"Reader"}', 200),
      ),
    );
    addTearDown(client.close);
    var moment = Moment(
      id: 'first',
      userName: 'Author',
      userAvatarUrl: '',
      timeAgo: '',
      backgroundImageUrl: '',
      unlockCondition: 'Scheduled',
      status: 'PUBLISHED',
      unlockAt: DateTime(2000),
    );
    late StateSetter changeCard;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [momentRouteObserver],
        builder: (context, child) =>
            ApiClientScope(client: client, child: child!),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              changeCard = setState;
              return MomentCard(moment: moment, scale: 1);
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final firstSocket = sockets.last;
    firstSocket.receive('connect');
    firstSocket.receive('moment:approved', {
      'momentId': 'first',
      'availability': {'isUnlocked': false},
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('moment-card-locked')), findsOneWidget);
    expect(find.byKey(const ValueKey('moment-card-unlocked')), findsNothing);
    firstSocket.receive('moment:unlocked', {
      'momentId': 'first',
      'availability': {'isUnlocked': true},
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('moment-card-unlocked')), findsOneWidget);
    changeCard(() => moment = moment.copyWith(id: 'second'));
    await tester.pump();
    expect(firstSocket.emissions.last.$1, 'moment:unwatch');
    expect(firstSocket.emissions.last.$2, {'momentId': 'first'});
    sockets.last.receive('connect');
    expect(sockets.last.emissions.single.$2, {'momentId': 'second'});
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'visible moment updates immediately; leaving unwatches; deletion hides content',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sockets = <FakeMomentSocket>[];
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://vera.aptechmedia.com'),
        initialAuthToken: 'test',
        momentSocketFactory: (url, options) {
          final socket = FakeMomentSocket();
          sockets.add(socket);
          return socket;
        },
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/profile')) {
            return http.Response(
              '{"id":"recipient","displayName":"Reader"}',
              200,
            );
          }
          return http.Response(
            '{"id":"moment","status":"PUBLISHED","hasMedia":false}',
            200,
          );
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
          home: const LockedMomentScreen(
            moment: Moment(
              id: 'moment',
              userName: 'Author',
              userAvatarUrl: '',
              timeAgo: '',
              backgroundImageUrl: '',
              unlockCondition: 'At the pinned location',
              status: 'PENDING_REVIEW',
              hasMedia: false,
            ),
          ),
        ),
      );
      await tester.pump();
      var socket = sockets.last;
      socket.receive('connect');
      socket.receive('moment:approved', {
        'momentId': 'moment',
        'availability': {'isUnlocked': false},
      });
      await tester.pump();
      expect(find.byType(LockedMomentScreen), findsOneWidget);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other page')),
        ),
      );
      await tester.pumpAndSettle();
      expect(socket.emissions.last.$1, 'moment:unwatch');
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      socket = sockets.last;
      socket.receive('connect');
      socket.receive('moment:unlocked', {
        'momentId': 'moment',
        'availability': {'isUnlocked': true},
      });
      await tester.pumpAndSettle();
      expect(find.byType(UnlockedMomentScreen), findsOneWidget);
      socket = sockets.last;
      socket.receive('connect');
      socket.receive('moment:status', {
        'momentId': 'moment',
        'availability': {'isUnlocked': false},
      });
      await tester.pumpAndSettle();
      expect(find.byType(LockedMomentScreen), findsOneWidget);
      sockets.last.receive('moment:deleted', {'momentId': 'moment'});
      await tester.pump();
      expect(find.text('This moment is no longer available.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
    },
  );
}
