import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/realtime/moment_realtime_route.dart';
import '../../../../core/realtime/moment_realtime_service.dart';
import '../../../../main.dart' show ApiClientScope;

/// Refreshes the visible For You feed on socket invalidation, without polling.
mixin ForYouLiveRefresh<T extends StatefulWidget> on State<T>
    implements RouteAware {
  bool get forYouRefreshActive;

  Future<void> loadForYouData({required bool showLoading});

  MomentRealtimeService? _realtime;
  StreamSubscription<String>? _subscription;
  StreamSubscription<void>? _connections;
  PageRoute<dynamic>? _route;
  Timer? _debounce;
  bool _subscribed = false;
  bool _foreground = true;
  bool _routeVisible = true;
  bool _fetching = false;
  bool _fetchAgain = false;
  AppLifecycleListener? _lifecycle;

  bool get _active =>
      mounted && forYouRefreshActive && _foreground && _routeVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycle ??= AppLifecycleListener(onStateChange: _onLifecycleState);
    final service = ApiClientScope.of(context).momentRealtime;
    if (!identical(service, _realtime)) {
      _unsubscribe();
      _subscription?.cancel();
      _realtime = service;
      _subscription = service.forYouChanges.listen((update) {
        if (!mounted) return;
        _scheduleRefresh();
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
    syncForYouActivity();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncForYouActivity();
  }

  void syncForYouActivity() {
    if (!_active) {
      _debounce?.cancel();
      _unsubscribe();
      return;
    }
    if (_subscribed) return;
    _subscribed = true;
    _realtime?.subscribeForYou();
    _scheduleRefresh();
  }

  void _unsubscribe() {
    if (!_subscribed) return;
    _subscribed = false;
    _realtime?.unsubscribeForYou();
  }

  void _scheduleRefresh() {
    if (!_active) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (_active) refreshForYou(showLoading: false);
    });
  }

  /// Serialize manual and automatic reads, retaining one follow-up invalidation.
  Future<void> refreshForYou({bool showLoading = true}) async {
    if (!_active) return;
    if (_fetching) {
      _fetchAgain = true;
      return;
    }
    _fetching = true;
    try {
      do {
        _fetchAgain = false;
        await loadForYouData(showLoading: showLoading);
        showLoading = false;
      } while (_fetchAgain && _active);
    } finally {
      _fetching = false;
    }
  }

  @override
  void didPush() {
    _routeVisible = true;
    syncForYouActivity();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    syncForYouActivity();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    syncForYouActivity();
  }

  @override
  void didPop() {
    _routeVisible = false;
    syncForYouActivity();
  }

  void _onLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    syncForYouActivity();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    _connections?.cancel();
    _unsubscribe();
    momentRouteObserver.unsubscribe(this);
    _lifecycle?.dispose();
    super.dispose();
  }
}
