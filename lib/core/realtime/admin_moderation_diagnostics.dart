import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Pass delivery metadata only: no tokens, payloads, or post contents.
void logAdminModeration(
  String event, [
  Map<String, Object?> metadata = const {},
]) {
  if (kDebugMode) {
    debugPrint('[ADMIN_MODERATION] $event ${jsonEncode(metadata)}');
  }
}
