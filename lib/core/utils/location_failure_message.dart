import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Explains a missing GPS fix without changing location proof or access rules.
String locationFailureMessage(Object error) {
  if (error is TimeoutException || error is PositionUpdateException) {
    const message =
        'Could not get your current location. Check Location Services and '
        'Precise Location permission, then try again.';
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS) {
      return '$message If using the iOS simulator, set a simulated location '
          'before trying again.';
    }
    return message;
  }
  return error.toString().replaceFirst('Exception: ', '');
}
