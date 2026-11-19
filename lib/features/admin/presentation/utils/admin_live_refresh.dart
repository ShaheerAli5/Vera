import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/realtime/moment_realtime_route.dart';
import '../../../../core/realtime/moment_realtime_service.dart';
import '../../../../main.dart' show ApiClientScope;

/// Admin-wide discovery has no documented socket room. Periodic reads discover
/// new IDs; per-moment socket watches invalidate already loaded queue entries.
mixin AdminLiveRefresh<T extends StatefulWidget> on State<T>
    implements RouteAware, WidgetsBindingObserver {
  bool get adminRefreshActive;
  Iterable<String> get adminWatchedMomentIds;
  Future<void> loadAdminData({required bool showLoading});

  MomentRealtimeService? _realtime;
  StreamSubscription<MomentRealtimeUpdate>? _subscription;
  PageRoute<dynamic>? _route;
  Timer? _timer;
  Timer? _debounce;
  final Set<String> _watchedIds = {};
  bool _foreground = true;
  bool _routeVisible = true;
  bool _fetching = false;
  bool _fetchAgain = false;
  bool _observing = false;

  bool get _active =>
      mounted && adminRefreshActive && _foreground && _routeVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    final service = ApiClientScope.of(context).momentRealtime;
    if (!identical(service, _realtime)) {
      _releaseWatches();
      _subscription?.cancel();
      _timer?.cancel();
      _timer = null;
      _realtime = service;
      _subscription = service.updates.listen((_) => _scheduleRefresh());
    }
    final route = ModalRoute.of(context);
    if (route is PageRoute && !identical(route, _route)) {
      momentRouteObserver.unsubscribe(this);
      _route = route;
      _routeVisible = route.isCurrent;
      momentRouteObserver.subscribe(this, route);
    }
    _updateActivity();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateActivity();
  }

  void _updateActivity() {
    if (!_active) {
      _timer?.cancel();
      _timer = null;
      _debounce?.cancel();
      _releaseWatches();
      return;
    }
    if (_timer != null) return;
    _syncWatches();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      refreshAdmin(showLoading: false);
    });
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    if (!_active) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (_active) refreshAdmin(showLoading: false);
    });
  }

  /// Serialize manual and automatic reads, retaining one follow-up invalidation.
  Future<void> refreshAdmin({bool showLoading = true}) async {
    if (!_active) return;
    if (_fetching) {
      _fetchAgain = true;
      return;
    }
    _fetching = true;
    try {
      do {
        _fetchAgain = false;
        await loadAdminData(showLoading: showLoading);
        if (mounted) _syncWatches();
        showLoading = false;
      } while (_fetchAgain && _active);
    } finally {
      _fetching = false;
    }
  }

  void _syncWatches() {
    final next = _active
        ? adminWatchedMomentIds.where((id) => id.isNotEmpty).toSet()
        : <String>{};
    for (final id in _watchedIds.difference(next)) {
      _realtime?.unwatch(id);
    }
    for (final id in next.difference(_watchedIds)) {
      _realtime?.watch(id);
    }
    _watchedIds
      ..clear()
      ..addAll(next);
  }

  void _releaseWatches() {
    for (final id in _watchedIds) {
      _realtime?.unwatch(id);
    }
    _watchedIds.clear();
  }

  @override
  void didPush() {
    _routeVisible = true;
    _updateActivity();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _updateActivity();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _updateActivity();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _updateActivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateActivity();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    _subscription?.cancel();
    _releaseWatches();
    momentRouteObserver.unsubscribe(this);
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
