import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vera/core/realtime/moment_realtime_service.dart';

import 'support/fake_moment_socket.dart';

void main() {
  test('socket failures expose safe categories without raw messages or tokens', () {
    final socket = FakeMomentSocket();
    final logs = <String>[];
    final previousPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = previousPrint);
    final service = MomentRealtimeService(
      baseUrl: 'https://example.com', token: 'private-token',
      socketFactory: (_, options) => socket,
    );
    addTearDown(service.dispose);
    service.watch('moment');
    for (final entry in {
      '429 Too many requests': 'rate_limit',
      'jwt expired': 'authorization',
      'WebSocketException': 'transport',
      'Failed host lookup': 'transport',
      'connection timed out': 'timeout',
      'invalid namespace': 'invalid_namespace',
      'io server disconnect': 'server_disconnect',
    }.entries) {
      socket.receive('connect_error', '${entry.key} Bearer private-token');
      expect(logs.last, contains('category=${entry.value}'));
      expect(logs.last, contains('hasAccessToken=true'));
      expect(logs.last, isNot(contains('private-token')));
      expect(logs.last, isNot(contains('Bearer')));
    }
  });
}
