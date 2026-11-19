import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';

import '../../features/home/domain/entities/moment.dart';

abstract interface class MomentSocket {
  bool get connected;
  void on(String event, void Function(dynamic) listener);
  void emit(String event, Map<String, dynamic> payload);
  void connect();
  void dispose();
}

typedef MomentSocketFactory =
    MomentSocket Function(String url, Map<String, dynamic> options);

class _IoMomentSocket implements MomentSocket {
  _IoMomentSocket(String url, Map<String, dynamic> options)
    : socket = io.io(url, options);
  final io.Socket socket;
  @override
  bool get connected => socket.connected;
  @override
  void on(String event, void Function(dynamic) listener) =>
      socket.on(event, listener);
  @override
  void emit(String event, Map<String, dynamic> payload) =>
      socket.emit(event, payload);
  @override
  void connect() => socket.connect();
  @override
  void dispose() => socket.dispose();
}

/// Partial socket state: only availability.isUnlocked controls unlocking.
class MomentRealtimeUpdate {
  const MomentRealtimeUpdate({
    required this.momentId,
    this.status,
    this.isUnlocked,
    this.deleted = false,
  });
  final String momentId;
  final String? status;
  final bool? isUnlocked;
  final bool deleted;

  static MomentRealtimeUpdate? parse(String event, dynamic payload) {
    if (payload is! Map) return null;
    var data = Map<String, dynamic>.from(payload);
    if (data['data'] is Map) {
      data = {...data, ...Map<String, dynamic>.from(data['data'] as Map)};
    }
    if (data['moment'] is Map) {
      data = {...data, ...Map<String, dynamic>.from(data['moment'] as Map)};
    }
    final id = data['momentId'] ?? data['id'];
    if (id is! String || id.isEmpty) return null;
    final availability = data['availability'];
    final unlocked = availability is Map ? availability['isUnlocked'] : null;
    const statuses = {
      'moment:submitted': 'PENDING_REVIEW',
      'moment:approved': 'PUBLISHED',
      'moment:rejected': 'REJECTED',
      'moment:deleted': 'DELETED',
    };
    return MomentRealtimeUpdate(
      momentId: id,
      status: data['status'] is String
          ? (data['status'] as String).toUpperCase()
          : statuses[event],
      isUnlocked: unlocked is bool ? unlocked : null,
      deleted: event == 'moment:deleted' || data['status'] == 'DELETED',
    );
  }

  MomentRealtimeUpdate merge(MomentRealtimeUpdate newer) =>
      MomentRealtimeUpdate(
        momentId: momentId,
        status: newer.status ?? status,
        isUnlocked: newer.isUnlocked ?? isUnlocked,
        deleted: deleted || newer.deleted,
      );

  Map<String, dynamic> applyToJson(Map<String, dynamic> raw) {
    final data = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw['moment'] is Map<String, dynamic>
        ? raw['moment'] as Map<String, dynamic>
        : raw;
    return {
      ...data,
      'id': momentId,
      if (status != null) 'status': deleted ? 'DELETED' : status,
      if (isUnlocked != null || deleted)
        'availability': {
          if (data['availability'] is Map)
            ...Map<String, dynamic>.from(data['availability'] as Map),
          'isUnlocked': deleted ? false : isUnlocked,
        },
    };
  }

  Moment apply(Moment moment) => moment.id != momentId
      ? moment
      : moment.copyWith(
          status: deleted ? 'DELETED' : status,
          isReadyToOpen: deleted ? false : isUnlocked,
        );
}

/// One connection per API session; multiple views share room subscriptions.
class MomentRealtimeService {
  MomentRealtimeService({
    required String baseUrl,
    String? token,
    MomentSocketFactory? socketFactory,
  }) : _url = Uri.parse(
         baseUrl,
       ).replace(path: '/moments', query: null, fragment: null).toString(),
       _token = token,
       _factory = socketFactory ?? _IoMomentSocket.new;

  static const events = [
    'moment:status',
    'moment:submitted',
    'moment:approved',
    'moment:rejected',
    'moment:unlocked',
    'moment:deleted',
  ];
  final String _url;
  final MomentSocketFactory _factory;
  String? _token;
  MomentSocket? _socket;
  final Map<String, int> _watches = {};
  final Map<String, MomentRealtimeUpdate> _latest = {};
  final _updates = StreamController<MomentRealtimeUpdate>.broadcast(sync: true);
  Stream<MomentRealtimeUpdate> get updates => _updates.stream;
  MomentRealtimeUpdate? latest(String id) => _latest[id];
  Moment applyLatest(Moment moment) =>
      _latest[moment.id]?.apply(moment) ?? moment;
  bool _disposed = false;

  void updateToken(String? token) {
    if (_disposed || token == _token) return;
    _token = token;
    _disconnect();
    if (token == null || token.isEmpty) _latest.clear();
    if (_watches.isNotEmpty) _connect();
  }

  void watch(String id) {
    if (_disposed || id.isEmpty) return;
    _watches[id] = (_watches[id] ?? 0) + 1;
    if (_socket == null) {
      _connect();
    } else if (_watches[id] == 1 && _socket!.connected) {
      _socket!.emit('moment:watch', {'momentId': id});
    }
  }

  void unwatch(String id) {
    final count = _watches[id];
    if (count == null) return;
    if (count > 1) {
      _watches[id] = count - 1;
      return;
    }
    _watches.remove(id);
    if (_socket?.connected == true) {
      _socket!.emit('moment:unwatch', {'momentId': id});
    }
    if (_watches.isEmpty) _disconnect();
  }

  void _connect() {
    if (_disposed || _token == null || _token!.isEmpty) return;
    final socket = _factory(_url, {
      'path': '/socket.io',
      'transports': ['websocket'],
      'auth': {'token': _token},
      'autoConnect': false,
      'forceNew': true,
      'multiplex': false,
      'reconnection': true,
    });
    _socket = socket;
    socket.on('connect', (_) {
      if (!identical(socket, _socket)) return;
      if (kDebugMode) debugPrint('[MOMENT_REALTIME] connected');
      for (final id in _watches.keys) {
        socket.emit('moment:watch', {'momentId': id});
      }
    });
    for (final event in ['connect_error', 'disconnect']) {
      socket.on(event, (_) {
        if (identical(socket, _socket) && kDebugMode) {
          // Do not log server error payloads: they can contain credentials.
          debugPrint('[MOMENT_REALTIME] $event');
        }
      });
    }
    for (final event in events) {
      socket.on(event, (payload) {
        if (!identical(socket, _socket)) return;
        final update = MomentRealtimeUpdate.parse(event, payload);
        if (update == null || !_watches.containsKey(update.momentId)) return;
        final combined = _latest[update.momentId]?.merge(update) ?? update;
        _latest[update.momentId] = combined;
        if (kDebugMode) debugPrint('[MOMENT_REALTIME] $event');
        _updates.add(combined);
      });
    }
    socket.connect();
  }

  void _disconnect() {
    final previous = _socket;
    _socket = null;
    previous?.dispose();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _disconnect();
    _watches.clear();
    _latest.clear();
    _updates.close();
  }
}
