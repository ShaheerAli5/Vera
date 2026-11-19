import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart' show ApiClientScope;
import '../../features/home/domain/entities/moment.dart';
import 'moment_realtime_service.dart';

final momentRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// Watches only while the containing page route is visible. Dialogs retain the watch.
mixin MomentRealtimeRoute<T extends StatefulWidget> on State<T>
    implements RouteAware {
  String get realtimeMomentId;
  void onMomentRealtime(MomentRealtimeUpdate update);
  MomentRealtimeService? _realtime;
  StreamSubscription<MomentRealtimeUpdate>? _subscription;
  PageRoute<dynamic>? _route;
  bool _watching = false;
  String? _watchedId;
  bool get realtimeDeleted =>
      _realtime?.latest(realtimeMomentId)?.deleted == true;
  Moment applyRealtime(Moment moment) =>
      _realtime?.applyLatest(moment) ?? moment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = ApiClientScope.of(context).momentRealtime;
    final route = ModalRoute.of(context);
    if (!identical(service, _realtime)) {
      _stopWatching();
      _subscription?.cancel();
      _realtime = service;
      _subscription = service.updates.listen((update) {
        if (mounted && _watching && update.momentId == realtimeMomentId) {
          onMomentRealtime(update);
        }
      });
    }
    if (route is PageRoute && !identical(route, _route)) {
      momentRouteObserver.unsubscribe(this);
      _route = route;
      momentRouteObserver.subscribe(this, route);
    }
    if (route?.isCurrent == true) _startWatching();
  }

  void _startWatching() {
    if (_watching) return;
    _watching = true;
    _watchedId = realtimeMomentId;
    _realtime?.watch(realtimeMomentId);
    final latest = _realtime?.latest(realtimeMomentId);
    if (latest != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _watching && latest.momentId == realtimeMomentId) {
          onMomentRealtime(latest);
        }
      });
    }
  }

  void _stopWatching() {
    if (!_watching) return;
    _watching = false;
    if (_watchedId != null) _realtime?.unwatch(_watchedId!);
    _watchedId = null;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_watchedId != null && _watchedId != realtimeMomentId) {
      _stopWatching();
      if (_route?.isCurrent == true) _startWatching();
    }
  }

  @override
  void didPush() => _startWatching();
  @override
  void didPopNext() => _startWatching();
  @override
  void didPushNext() => _stopWatching();
  @override
  void didPop() => _stopWatching();

  Widget deletedMomentView() => Scaffold(
    appBar: AppBar(title: const Text('Moment deleted')),
    body: const Center(child: Text('This moment is no longer available.')),
  );

  @override
  void dispose() {
    momentRouteObserver.unsubscribe(this);
    _stopWatching();
    _subscription?.cancel();
    super.dispose();
  }
}
