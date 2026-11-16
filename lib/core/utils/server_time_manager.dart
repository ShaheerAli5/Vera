import 'dart:async';
import 'package:flutter/widgets.dart';

class ServerTimeManager extends WidgetsBindingObserver {
  ServerTimeManager._internal() {
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  static final ServerTimeManager instance = ServerTimeManager._internal();

  Duration _serverOffset = Duration.zero;
  Timer? _timer;
  final ValueNotifier<int> _tickerNotifier = ValueNotifier<int>(0);
  final List<VoidCallback> _onResumedListeners = [];

  ValueNotifier<int> get ticker => _tickerNotifier;

  void addResumedListener(VoidCallback listener) {
    if (!_onResumedListeners.contains(listener)) {
      _onResumedListeners.add(listener);
    }
  }

  void removeResumedListener(VoidCallback listener) {
    _onResumedListeners.remove(listener);
  }

  void updateServerTime(DateTime? serverTime) {
    if (serverTime != null) {
      _serverOffset = serverTime.difference(DateTime.now());
    }
  }

  DateTime get now => DateTime.now().add(_serverOffset);

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickerNotifier.value++;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      for (final listener in List<VoidCallback>.from(_onResumedListeners)) {
        try {
          listener();
        } catch (_) {}
      }
    }
  }

  static int getTimezoneOffsetMinutes(String ianaTz) {
    final tz = ianaTz.trim().toUpperCase();
    switch (tz) {
      case 'UTC':
      case 'GMT':
        return 0;
      case 'ASIA/KARACHI':
      case 'PKT':
        return 300;
      case 'ASIA/KOLKATA':
      case 'IST':
        return 330;
      case 'ASIA/DUBAI':
      case 'GST':
        return 240;
      case 'ASIA/SINGAPORE':
      case 'SGT':
        return 480;
      case 'ASIA/TOKYO':
      case 'JST':
        return 540;
      case 'AUSTRALIA/SYDNEY':
      case 'AEST':
      case 'AEDT':
        return 600;
      case 'EUROPE/PARIS':
      case 'CET':
      case 'CEST':
        return 60;
      case 'EUROPE/LONDON':
      case 'BST':
        return 0;
      case 'AMERICA/NEW_YORK':
      case 'EST':
      case 'EDT':
        return -300;
      case 'AMERICA/CHICAGO':
      case 'CST':
      case 'CDT':
        return -360;
      case 'AMERICA/DENVER':
      case 'MST':
      case 'MDT':
        return -420;
      case 'AMERICA/LOS_ANGELES':
      case 'PST':
      case 'PDT':
        return -480;
      default:
        return DateTime.now().timeZoneOffset.inMinutes;
    }
  }

  static String computeUtcIsoString({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required String timezone,
  }) {
    final offsetMinutes = getTimezoneOffsetMinutes(timezone);
    final utcDt = DateTime.utc(year, month, day, hour, minute)
        .subtract(Duration(minutes: offsetMinutes));
    return utcDt.toIso8601String();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}
