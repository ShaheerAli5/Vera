import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'user_role.dart';

String diagnosticRole(String? role) => role == null || role.trim().isEmpty
    ? 'missing'
    : UserRole.parse(role)?.value ?? 'unknown';

/// Log metadata only. Never include OTPs, email addresses, tokens or HTTP bodies.
void logAuthFlow(String event, Map<String, Object?> metadata) {
  if (!kDebugMode) return;
  const allowed = {
    'stage', 'path', 'method', 'httpStatus', 'elapsedMs', 'attempt',
    'hasAccessToken', 'hasRefreshToken', 'hasUser', 'savedRole',
    'responseRole', 'parsedRole', 'decision', 'errorType', 'destination',
  };
  final safe = Map<String, Object?>.fromEntries(
    metadata.entries.where((entry) => allowed.contains(entry.key)),
  );
  debugPrint('[AUTH_FLOW] $event ${jsonEncode(safe)}');
}
