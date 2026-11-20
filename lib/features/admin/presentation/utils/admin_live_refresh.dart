import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/realtime/moment_realtime_route.dart';
import '../../../../core/realtime/moment_realtime_service.dart';
import '../../../../core/realtime/admin_moderation_update.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../main.dart' show ApiClientScope;

/// Keeps the active admin tab subscribed, including when the queue is empty.
mixin AdminLiveRefresh<T extends StatefulWidget> on State<T>
    implements RouteAware, WidgetsBindingObserver {
  bool get adminRefreshActive;

  /// Return true when full REST records need refreshing after this event.
  bool onAdminModeration(AdminModerationUpdate update) => update.isTransition;
  ModerationCounts? get liveModerationCounts => _realtime?.moderationCounts;
  AdminModerationUpdate? moderationState(String id) =>
      _realtime?.moderationState(id);
  Future<void> loadAdminData({required bool showLoading});

  MomentRealtimeService? _realtime;
  StreamSubscription<AdminModerationUpdate>? _subscription;
  StreamSubscription<void>? _connections;
  PageRoute<dynamic>? _route;
  Timer? _debounce;
  bool _subscribed = false;
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
      _unsubscribe();
      _subscription?.cancel();
      _realtime = service;
      _subscription = service.moderationUpdates.listen((update) {
        if (!mounted) return;
        if (update.serverTime != null) {
          ServerTimeManager.instance.updateServerTime(update.serverTime!);
        }
        if (onAdminModeration(update)) _scheduleRefresh();
      });
      _connections?.cancel();
      _connections = service.connections.listen((_) => _scheduleRefresh());
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
      _debounce?.cancel();
      _unsubscribe();
      return;
    }
    if (_subscribed) return;
    _subscribed = true;
    _realtime?.subscribeModeration();
    _scheduleRefresh();
  }

  void _unsubscribe() {
    if (!_subscribed) return;
    _subscribed = false;
    _realtime?.unsubscribeModeration();
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
        showLoading = false;
      } while (_fetchAgain && _active);
    } finally {
      _fetching = false;
    }
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
    _debounce?.cancel();
    _subscription?.cancel();
    _connections?.cancel();
    _unsubscribe();
    momentRouteObserver.unsubscribe(this);
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
