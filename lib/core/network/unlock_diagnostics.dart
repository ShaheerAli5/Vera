import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Only pass diagnostic metadata here, never request/response bodies or headers.
void logUnlockDiagnostic(String event, Map<String, Object?> metadata) {
  if (!kDebugMode) return;
  debugPrint('[MOMENT_UNLOCK] $event ${jsonEncode(metadata)}');
}

void logApprovalDiagnostic(String event, Map<String, Object?> metadata) {
  if (!kDebugMode) return;
  debugPrint('[ADMIN_APPROVAL] $event ${jsonEncode(metadata)}');
}

void logChatDiagnostic(String event, Map<String, Object?> metadata) {
  if (!kDebugMode) return;
  debugPrint('[MOMENT_CHAT] $event ${jsonEncode(metadata)}');
}

String redactUnlockError(String message) {
  return message
      .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false), '[redacted]')
      .replaceAll(
        RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
        '[redacted]',
      )
      .replaceAll(
        RegExp(
          r'''["']?(?:latitude|longitude|lat|lng|lon|password|accessToken|refreshToken|token|authorization)["']?\s*[:=]\s*(?:"[^"]*"|'[^']*'|[^\s,;}]+)''',
          caseSensitive: false,
        ),
        '[redacted]',
      )
      .replaceAll(RegExp(r'-?\d+\.\d+'), '[number]');
}
