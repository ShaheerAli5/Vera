import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_exception.dart';

void logMomentUpload(String event, Map<String, Object?> metadata) {
  if (!kDebugMode) return;
  const allowed = {
    'stage', 'momentId', 'version', 'httpStatus', 'elapsedMs', 'errorType',
    'validationFields', 'mediaSizeBytes', 'mediaType', 'visibility', 'unlockType',
    'recipientCount', 'inviteCount', 'hasCoordinates', 'hasPlaceName',
    'hasUnlockTime', 'hasAccessToken',
  };
  debugPrint('[MOMENT_UPLOAD] $event ${jsonEncode(Map<String, Object?>.fromEntries(
    metadata.entries.where((entry) => allowed.contains(entry.key)),
  ))}');
}

Map<String, Object?> momentUploadError(Object error) {
  if (error is! ApiException) {
    return {'errorType': error is FormatException ? 'response_format' : error.runtimeType.toString()};
  }
  final fields = <String>{};
  for (final field in [
    'title', 'category', 'teaser', 'message', 'visibility', 'recipientUserIds',
    'inviteEmails', 'unlockRule', 'latitude', 'longitude', 'radiusM', 'placeName',
    'unlockAt', 'timezone', 'expiresAt', 'version', 'media',
  ]) {
    if (RegExp('\\b$field\\b').hasMatch(error.message)) fields.add(field);
  }
  final category = switch (error.statusCode) {
    400 || 422 => 'validation',
    401 => 'authentication',
    403 => 'permission',
    409 => 'conflict',
    413 => 'file_too_large',
    415 => 'unsupported_media',
    429 => 'rate_limit',
    >= 500 => 'server',
    0 => error.code == 'timeout' ? 'timeout' : 'network',
    _ => 'api',
  };
  return {'httpStatus': error.statusCode, 'errorType': category,
    if (fields.isNotEmpty) 'validationFields': fields.toList()};
}

Future<T> traceMomentUpload<T>(
  String stage, Future<T> Function() action, {
  Map<String, Object?> metadata = const {},
}) async {
  final timer = Stopwatch()..start();
  logMomentUpload('step_started', {...metadata, 'stage': stage});
  try {
    final result = await action();
    logMomentUpload('step_completed', {...metadata, 'stage': stage, 'elapsedMs': timer.elapsedMilliseconds});
    return result;
  } catch (error) {
    logMomentUpload('step_failed', {...metadata, 'stage': stage,
      'elapsedMs': timer.elapsedMilliseconds, ...momentUploadError(error)});
    rethrow;
  }
}
