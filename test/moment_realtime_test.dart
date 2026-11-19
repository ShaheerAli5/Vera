import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/realtime/moment_realtime_service.dart';
import 'package:vera/features/home/domain/entities/moment.dart';

import 'support/fake_moment_socket.dart';

const moment = Moment(
  id: 'moment',
  userName: 'Author',
  userAvatarUrl: '',
  timeAgo: '',
  backgroundImageUrl: '',
  unlockCondition: '',
  status: 'PENDING_REVIEW',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MomentRealtimeService service;
  late List<FakeMomentSocket> sockets;
  late List<Map<String, dynamic>> options;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sockets = [];
    options = [];
    service = MomentRealtimeService(
      baseUrl: 'https://vera.aptechmedia.com',
      token: 'old',
      socketFactory: (url, configuration) {
        expect(url, 'https://vera.aptechmedia.com/moments');
        options.add(configuration);
        final socket = FakeMomentSocket();
        sockets.add(socket);
        return socket;
      },
    );
  });
  tearDown(() => service.dispose());

  test('connect contract, reference counted watches and final unwatch', () {
    service.watch('moment');
    service.watch('moment');
    expect(sockets.length, 1);
    expect(options.single['path'], '/socket.io');
    expect(options.single['transports'], ['websocket']);
    expect(options.single['auth'], {'token': 'old'});
    expect(options.single['forceNew'], isTrue);
    sockets.single.receive('connect');
    expect(sockets.single.emissions.length, 1);
    expect(sockets.single.emissions.single.$1, 'moment:watch');
    expect(sockets.single.emissions.single.$2, {'momentId': 'moment'});
    service.unwatch('moment');
    expect(sockets.single.emissions.length, 1);
    service.unwatch('moment');
    expect(sockets.single.emissions.last.$1, 'moment:unwatch');
    expect(sockets.single.emissions.last.$2, {'momentId': 'moment'});
    expect(sockets.single.disposed, isTrue);
  });

  test('transport reconnect re-watches all current rooms', () {
    service.watch('moment');
    service.watch('second');
    sockets.single.receive('connect');
    service.unwatch('second');
    sockets.single.emissions.clear();
    sockets.single.receive('connect');
    expect(sockets.single.emissions.length, 1);
    expect(sockets.single.emissions.single.$1, 'moment:watch');
    expect(sockets.single.emissions.single.$2, {'momentId': 'moment'});
  });

  test(
    'token rotation creates a fresh authenticated socket and ignores old events',
    () {
      service.watch('moment');
      final old = sockets.single;
      old.receive('connect');
      service.updateToken('new');
      expect(old.disposed, isTrue);
      expect(options.last['auth'], {'token': 'new'});
      old.receive('moment:unlocked', {
        'momentId': 'moment',
        'availability': {'isUnlocked': true},
      });
      expect(service.latest('moment'), isNull);
      sockets.last.receive('connect');
      expect(sockets.last.emissions.single.$1, 'moment:watch');
      service.updateToken(null);
      expect(sockets.last.disposed, isTrue);
      expect(service.latest('moment'), isNull);
    },
  );

  test(
    'approval never unlocks; explicit false overrides due time and timestamps',
    () {
      service.watch('moment');
      final socket = sockets.single;
      socket.receive('moment:approved', {'momentId': 'moment'});
      expect(service.applyLatest(moment).isReadyToOpen, isFalse);
      socket.receive('moment:approved', {
        'momentId': 'moment',
        'isUnlocked': true,
        'availability': {'isApproved': true, 'isUnlocked': false},
      });
      final staleRest = moment.copyWith(
        status: 'PUBLISHED',
        isReadyToOpen: true,
        unlockAt: DateTime(2000),
        unlockedAt: DateTime(2000),
      );
      expect(service.applyLatest(staleRest).isReadyToOpen, isFalse);
      socket.receive('moment:unlocked', {'momentId': 'moment'});
      expect(service.applyLatest(staleRest).isReadyToOpen, isFalse);
      socket.receive('moment:unlocked', {
        'momentId': 'moment',
        'availability': {'isUnlocked': true},
      });
      expect(service.applyLatest(moment).isReadyToOpen, isTrue);
      socket.receive('moment:status', {
        'momentId': 'moment',
        'availability': {'isUnlocked': false},
      });
      expect(service.applyLatest(staleRest).isReadyToOpen, isFalse);
    },
  );

  test('all six events update partial state and deletion remains terminal', () {
    service.watch('moment');
    final received = <MomentRealtimeUpdate>[];
    final subscription = service.updates.listen(received.add);
    addTearDown(subscription.cancel);
    final socket = sockets.single;
    socket.receive('moment:status', {
      'data': {'momentId': 'moment', 'status': 'DRAFT'},
    });
    socket.receive('moment:submitted', {'momentId': 'moment'});
    expect(service.applyLatest(moment).status, 'PENDING_REVIEW');
    socket.receive('moment:approved', {'momentId': 'moment'});
    expect(service.applyLatest(moment).status, 'PUBLISHED');
    socket.receive('moment:rejected', {
      'moment': {'id': 'moment'},
    });
    expect(service.applyLatest(moment).status, 'REJECTED');
    socket.receive('moment:unlocked', {
      'momentId': 'moment',
      'availability': {'isUnlocked': true},
    });
    socket.receive('moment:deleted', {'momentId': 'moment'});
    expect(received.length, 6);
    expect(service.applyLatest(moment).isReadyToOpen, isFalse);
    expect(service.applyLatest(moment).status, 'DELETED');
    socket.receive('moment:status', {
      'momentId': 'moment',
      'availability': {'isUnlocked': true},
    });
    expect(service.applyLatest(moment).status, 'DELETED');
  });

  test('unknown IDs and malformed payloads cannot change a watched moment', () {
    service.watch('moment');
    final socket = sockets.single;
    for (final payload in [
      null,
      'bad',
      {},
      {'momentId': 12},
      {'momentId': 'other'},
    ]) {
      socket.receive('moment:approved', payload);
    }
    expect(service.latest('moment'), isNull);
    socket.receive('moment:status', {
      'momentId': 'moment',
      'availability': {'isUnlocked': 'true'},
    });
    expect(service.applyLatest(moment).isReadyToOpen, isFalse);
  });

  test(
    'actual API refresh propagates new access token to watched socket',
    () async {
      final configurations = <Map<String, dynamic>>[];
      final connectedSockets = <FakeMomentSocket>[];
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://vera.aptechmedia.com'),
        initialAuthToken: 'old',
        initialRefreshToken: 'refresh',
        momentSocketFactory: (url, configuration) {
          configurations.add(configuration);
          final socket = FakeMomentSocket();
          connectedSockets.add(socket);
          return socket;
        },
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'accessToken': 'new', 'refreshToken': 'new-refresh'}),
            200,
          ),
        ),
      );
      addTearDown(client.close);
      client.momentRealtime.watch('moment');
      expect(await client.refreshSession(), isTrue);
      expect(configurations.last['auth'], {'token': 'new'});
      expect(connectedSockets.first.disposed, isTrue);
      await client.setAuthToken('third');
      expect(configurations.last['auth'], {'token': 'third'});
      await client.clearTokens();
      expect(connectedSockets.last.disposed, isTrue);
    },
  );
}
