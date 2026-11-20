import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';

import '../../features/home/domain/entities/moment.dart';
import 'admin_moderation_update.dart';
import 'admin_moderation_diagnostics.dart';

abstract interface class MomentSocket {
  bool get connected;
  void on(String event, void Function(dynamic) listener);
  void emit(String event, [Map<String, dynamic>? payload]);
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
  void emit(String event, [Map<String, dynamic>? payload]) =>
      socket.emit(event, payload);
  @override
  void connect() => socket.connect();
  @override
  void dispose() => socket.dispose();
}

/// Recipient unlocking uses availability.isUnlocked; preview permission is separate.
class MomentRealtimeUpdate {
  const MomentRealtimeUpdate({
    required this.momentId,
    this.status,
    this.isUnlocked,
    this.isApproved,
    this.canPreview,
    this.invitationStatus,
    this.deleted = false,
  });
  final String momentId;
  final String? status;
  final bool? isUnlocked;
  final bool? isApproved;
  final bool? canPreview;
  final String? invitationStatus;
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
    final viewer = data['viewer'];
    final preview = viewer is Map ? viewer['canPreview'] ?? data['canPreview'] ?? viewer['isCreator'] : data['canPreview'];
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
      isApproved: availability is Map && availability['isApproved'] is bool
          ? availability['isApproved'] as bool
          : null,
      canPreview: preview is bool ? preview : null,
      invitationStatus: data['invitationStatus'] is String
          ? (data['invitationStatus'] as String).toUpperCase()
          : null,
      deleted: event == 'moment:deleted' || data['status'] == 'DELETED',
    );
  }

  MomentRealtimeUpdate merge(MomentRealtimeUpdate newer) =>
      MomentRealtimeUpdate(
        momentId: momentId,
        status: newer.status ?? status,
        isUnlocked: newer.isUnlocked ?? isUnlocked,
        isApproved: newer.isApproved ?? isApproved,
        canPreview: newer.canPreview ?? canPreview,
        invitationStatus: newer.invitationStatus ?? invitationStatus,
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
      if (invitationStatus != null) 'invitationStatus': invitationStatus,
      if (canPreview != null || deleted)
        'viewer': {
          if (data['viewer'] is Map) ...Map<String, dynamic>.from(data['viewer'] as Map),
          'canPreview': deleted ? false : canPreview,
        },
      if (status != null) 'status': deleted ? 'DELETED' : status,
      if (isUnlocked != null || isApproved != null || deleted)
        'availability': {
          if (data['availability'] is Map)
            ...Map<String, dynamic>.from(data['availability'] as Map),
          if (isUnlocked != null || deleted)
            'isUnlocked': deleted ? false : isUnlocked,
          if (isApproved != null) 'isApproved': isApproved,
        },
    };
  }

  Moment apply(Moment moment) {
    if (moment.id != momentId) return moment;
    final invite = invitationStatus ?? moment.invitationStatus;
    final approved = isApproved ?? moment.isApproved;
    final preview = !deleted && (canPreview ?? moment.canPreview);
    final previewRevoked = moment.canPreview && canPreview == false;
    final unlocked = isUnlocked ?? (!previewRevoked && moment.isReadyToOpen);
    final recipientAccess = approved != false &&
        invite != 'PENDING' && invite != 'DECLINED' && unlocked;
    return moment.copyWith(
      status: deleted ? 'DELETED' : status,
      invitationStatus: invite,
      isApproved: approved,
      canPreview: preview,
      isReadyToOpen: !deleted && (preview || recipientAccess),
    );
  }
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
  int _adminSubscribers = 0;
  int _forYouSubscribers = 0;
  final _forYouChanges = StreamController<String>.broadcast(sync: true);
  Stream<String> get forYouChanges => _forYouChanges.stream;

  void subscribeForYou() {
    if (_disposed) return;
    _forYouSubscribers++;
    if (_socket == null) {
      _connect();
    } else if (_forYouSubscribers == 1 && _socket!.connected) {
      _socket!.emit('home:for-you:subscribe');
    }
  }

  void unsubscribeForYou() {
    if (_forYouSubscribers == 0) return;
    _forYouSubscribers--;
    if (_forYouSubscribers == 0 && _socket?.connected == true) {
      _socket!.emit('home:for-you:unsubscribe');
    }
    if (!_hasDemand) _disconnect();
  }

  int _moderationRevision = 0;
  int get moderationRevision => _moderationRevision;
  bool _moderationConfirmed = false;
  bool get moderationFeedConfirmed =>
      _moderationConfirmed && _socket?.connected == true;

  void _requestModerationSubscription() {
    _moderationConfirmed = false;
    _socket!.emit('admin:moderation:subscribe');
    logAdminModeration('subscribe_sent');
  }

  void ensureModerationSubscription() {
    if (_adminSubscribers > 0 &&
        _socket?.connected == true &&
        !_moderationConfirmed) {
      _requestModerationSubscription();
    }
  }

  ModerationCounts reconcileModerationCounts(
    ModerationCounts counts,
    int beforeRevision,
  ) {
    if (_disposed || _token == null || _token!.isEmpty) return counts;
    // Only socket updates received during this HTTP read take precedence.
    if (_moderationRevision != beforeRevision && _moderationCounts != null) {
      return _moderationCounts!;
    }
    _moderationCounts = counts;
    logAdminModeration('http_counts_reconciled', {
      'pendingReview': counts.pendingReview,
      'approved': counts.approved,
      'rejected': counts.rejected,
      'feedConfirmed': moderationFeedConfirmed,
    });
    // Keep hidden admin tabs synchronized without triggering another HTTP read.
    _moderationUpdates.add(AdminModerationUpdate(counts: counts));
    return counts;
  }

  int reconcilePendingTotal(int pending, int beforeRevision) {
    final current = _moderationCounts;
    if (current == null) return pending;
    return reconcileModerationCounts(
      ModerationCounts(
        pendingReview: pending,
        approved: current.approved,
        rejected: current.rejected,
      ),
      beforeRevision,
    ).pendingReview;
  }

  final _moderationUpdates = StreamController<AdminModerationUpdate>.broadcast(
    sync: true,
  );
  Stream<AdminModerationUpdate> get moderationUpdates =>
      _moderationUpdates.stream;
  ModerationCounts? _moderationCounts;
  ModerationCounts? get moderationCounts => _moderationCounts;
  DateTime? _moderationCountsTime;
  final Map<String, AdminModerationUpdate> _moderationMoments = {};
  AdminModerationUpdate? moderationState(String id) => _moderationMoments[id];
  bool get _hasDemand => _watches.isNotEmpty || _adminSubscribers > 0 || _forYouSubscribers > 0;

  void subscribeModeration() {
    if (_disposed) return;
    _adminSubscribers++;
    if (_socket == null) {
      _connect();
    } else if (_adminSubscribers == 1 && _socket!.connected) {
      _requestModerationSubscription();
    }
  }

  void unsubscribeModeration() {
    if (_adminSubscribers == 0) return;
    _adminSubscribers--;
    if (_adminSubscribers == 0 && _socket?.connected == true) {
      _socket!.emit('admin:moderation:unsubscribe');
      _moderationConfirmed = false;
      logAdminModeration('unsubscribe_sent');
    }
    if (!_hasDemand) _disconnect();
  }

  final Map<String, MomentRealtimeUpdate> _latest = {};
  final Map<String, int> _socketVersions = {};
  final Expando<int> _stateSocketVersions = Expando<int>();
  final _connections = StreamController<void>.broadcast(sync: true);
  Stream<void> get connections => _connections.stream;
  Map<String, MomentRealtimeUpdate> get snapshot => Map.unmodifiable(_latest);
  final _updates = StreamController<MomentRealtimeUpdate>.broadcast(sync: true);
  Stream<MomentRealtimeUpdate> get updates => _updates.stream;
  MomentRealtimeUpdate? latest(String id) => _latest[id];
  Moment applyLatest(Moment moment) =>
      _latest[moment.id]?.apply(moment) ?? moment;

  /// A completed REST read supersedes older socket state, unless an event
  /// arrived while that read was in flight.
  Moment reconcileRest(
    Moment moment,
    MomentRealtimeUpdate? before, {
    bool mutation = false,
  }) {
    final beforeVersion = before == null
        ? 0
        : (_stateSocketVersions[before] ?? 0);
    final socketChanged = beforeVersion != (_socketVersions[moment.id] ?? 0);
    if (!identical(_latest[moment.id], before) &&
        (!mutation || socketChanged)) {
      return applyLatest(moment);
    }
    final state = MomentRealtimeUpdate(
      momentId: moment.id,
      status: moment.status,
      invitationStatus: moment.invitationStatus,
      isUnlocked: moment.canAccessContent,
      isApproved: moment.isApproved,
      deleted: moment.status == 'DELETED' || before?.deleted == true,
    );
    _stateSocketVersions[state] = _socketVersions[moment.id] ?? 0;
    _latest[moment.id] = state;
    return state.apply(moment);
  }

  bool _disposed = false;

  void updateToken(String? token) {
    if (_disposed || token == _token) return;
    _token = token;
    _disconnect();
    if (token == null || token.isEmpty) {
      _latest.clear();
      _socketVersions.clear();
      _moderationCounts = null;
      _moderationCountsTime = null;
      _moderationMoments.clear();
    }
    if (_hasDemand) _connect();
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
    if (!_hasDemand) _disconnect();
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
      if (_adminSubscribers > 0) _requestModerationSubscription();
      if (_forYouSubscribers > 0) socket.emit('home:for-you:subscribe');
      _connections.add(null);
    });
    for (final event in ['connect_error', 'disconnect']) {
      socket.on(event, (error) {
        if (!identical(socket, _socket)) return;
        _moderationConfirmed = false;
        if (kDebugMode) debugPrint('[MOMENT_REALTIME] $event');
        if (_adminSubscribers > 0) {
          logAdminModeration(event, {
            'feedConfirmed': false,
            if (event == 'connect_error')
              'category': _connectionErrorCategory(error),
          });
        }
      });
    }
    socket.on('home:for-you:changed', (payload) {
      if (!identical(socket, _socket) || _forYouSubscribers == 0 || payload is! Map) return;
      final reason = payload['reason'];
      if (reason != 'PUBLIC_MOMENT_PUBLISHED' && reason != 'PUBLIC_MOMENT_REMOVED') return;
      _forYouChanges.add(reason as String);
    });
    for (final event in events) {
      socket.on(event, (payload) {
        if (!identical(socket, _socket)) return;
        final update = MomentRealtimeUpdate.parse(event, payload);
        if (update == null || !_watches.containsKey(update.momentId)) return;
        final combined = _latest[update.momentId]?.merge(update) ?? update;
        final version = (_socketVersions[update.momentId] ?? 0) + 1;
        _socketVersions[update.momentId] = version;
        _stateSocketVersions[combined] = version;
        _latest[update.momentId] = combined;
        if (kDebugMode) debugPrint('[MOMENT_REALTIME] $event');
        _updates.add(combined);
      });
    }
    for (final event in [
      'admin:moderation:subscribed',
      'admin:moderation:submitted',
      'admin:moderation:approved',
      'admin:moderation:rejected',
      'admin:moderation:deleted',
      'admin:moderation:update',
    ]) {
      socket.on(event, (payload) {
        if (!identical(socket, _socket) || _adminSubscribers == 0) return;
        final update = AdminModerationUpdate.parse(event, payload);
        if (update == null) {
          logAdminModeration('payload_rejected', {
            'event': event,
            'isMap': payload is Map,
          });
          return;
        }
        if (event == 'admin:moderation:subscribed') _moderationConfirmed = true;
        if (update.isTransition) {
          final previous = _moderationMoments[update.momentId];
          if (previous?.version != null && update.version != null) {
            if (update.version! < previous!.version!) return;
            if (update.version == previous.version &&
                update.transition == previous.transition) {
              return;
            }
          }
          _moderationMoments.remove(update.momentId);
          _moderationMoments[update.momentId!] = update;
          // Bound the transition ledger for long-lived admin sessions.
          if (_moderationMoments.length > 512) {
            _moderationMoments.remove(_moderationMoments.keys.first);
          }
        }
        if (update.counts != null &&
            (_moderationCountsTime == null ||
                update.serverTime == null ||
                !update.serverTime!.isBefore(_moderationCountsTime!))) {
          _moderationCounts = update.counts;
          _moderationCountsTime = update.serverTime;
        }
        _moderationRevision++;
        logAdminModeration(event, {
          'hasCounts': update.counts != null,
          'hasMomentId': update.momentId != null,
          'version': update.version,
          'feedConfirmed': moderationFeedConfirmed,
        });
        _moderationUpdates.add(update);
      });
    }
    socket.connect();
  }

  String _connectionErrorCategory(Object? error) {
    // Classify in memory; never print raw errors, which may contain credentials.
    final description = error.toString().toLowerCase();
    if (description.contains('invalid namespace')) return 'invalid_namespace';
    if (description.contains('unauthorized') ||
        description.contains('forbidden')) {
      return 'authorization';
    }
    if (description.contains('timeout') || description.contains('timed out')) {
      return 'timeout';
    }
    if (description.contains('websocket') ||
        description.contains('socketexception')) {
      return 'transport';
    }
    return 'unknown';
  }

  void _disconnect() {
    final previous = _socket;
    _socket = null;
    _moderationConfirmed = false;
    previous?.dispose();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _disconnect();
    _watches.clear();
    _adminSubscribers = 0;
    _forYouSubscribers = 0;
    _forYouChanges.close();
    _moderationMoments.clear();
    _moderationCounts = null;
    _latest.clear();
    _socketVersions.clear();
    _updates.close();
    _connections.close();
    _moderationUpdates.close();
  }
}
