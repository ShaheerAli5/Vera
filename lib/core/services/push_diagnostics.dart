import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Pass only delivery metadata. Never pass tokens, headers, or message contents.
void logPushDiagnostic(String event, Map<String, Object?> metadata) {
  if (kDebugMode) debugPrint('[PUSH] $event ${jsonEncode(metadata)}');
}
