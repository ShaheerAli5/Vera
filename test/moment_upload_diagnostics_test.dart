import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/network/api_exception.dart';
import 'package:vera/core/network/moment_upload_diagnostics.dart';
import 'package:vera/features/home/data/datasources/moments_remote_data_source.dart';
import 'package:vera/features/home/data/models/create_moment_params.dart';

const params = CreateMomentParams(
  title: 'private-title', category: 'OTHER', message: 'private-message',
  inviteEmails: ['private@example.com'],
  unlockRule: MomentUnlockRule(type: 'LOCATION', latitude: 12.345678,
    longitude: -98.765432, radiusM: 100, placeName: 'private-place'),
);

void main() {
  late List<String> logs;
  late DebugPrintCallback originalPrint;
  setUp(() {
    logs = [];
    originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
  });
  tearDown(() => debugPrint = originalPrint);

  test('creation, media and publication log each step with actual HTTP status', () async {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      initialAuthToken: 'private-token',
      httpClient: MockClient((request) async => http.Response(jsonEncode({
        'id': 'moment', 'version': request.url.path.endsWith('/media') ? 2 : 1,
        'status': request.url.path.endsWith('/publish') ? 'PENDING_REVIEW' : 'DRAFT',
      }), 201)),
    );
    addTearDown(client.close);
    final source = MomentsRemoteDataSource(client);
    final created = await source.createMoment(params);
    final uploaded = await source.uploadMomentMedia(momentId: created.id,
      version: created.version, bytes: [1, 2, 3], filename: 'private-photo.jpg');
    await source.publishMoment(momentId: created.id, version: uploaded.version);
    for (final stage in ['create', 'media_upload', 'publish']) {
      expect(logs.any((line) => line.contains('http_response') && line.contains('"stage":"$stage"') && line.contains('"httpStatus":201')), isTrue);
      expect(logs.any((line) => line.contains('step_completed') && line.contains('"stage":"$stage"')), isTrue);
    }
    final output = logs.join('\n');
    expect(output, contains('"mediaSizeBytes":3'));
    expect(output, contains('"mediaType":"image/jpeg"'));
    for (final secret in ['private-token', 'private-title', 'private-message',
      'private@example.com', 'private-place', 'private-photo.jpg', '12.345678', '-98.765432']) {
      expect(output, isNot(contains(secret)));
    }
  });

  for (final stage in ['create', 'media_upload', 'publish']) {
    test('$stage failure identifies the failing step and omits backend private values', () async {
      final status = stage == 'media_upload' ? 413 : stage == 'publish' ? 409 : 400;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        httpClient: MockClient((_) async => http.Response(jsonEncode({
          'message': 'longitude 12.345678 private-message private@example.com',
        }), status)),
      );
      addTearDown(client.close);
      final source = MomentsRemoteDataSource(client);
      final Future<dynamic> request = switch (stage) {
        'create' => source.createMoment(params),
        'media_upload' => source.uploadMomentMedia(momentId: 'moment', version: 1,
          bytes: [1, 2, 3], filename: 'private-photo.jpg'),
        _ => source.publishMoment(momentId: 'moment', version: 2),
      };
      await expectLater(request, throwsA(isA<ApiException>()));
      final failed = logs.singleWhere((line) => line.contains('step_failed'));
      expect(failed, contains('"stage":"$stage"'));
      expect(failed, contains('"httpStatus":$status'));
      expect(failed, contains('"validationFields"'));
      expect(failed, isNot(contains('12.345678')));
      expect(failed, isNot(contains('private-message')));
      expect(failed, isNot(contains('private@example.com')));
    });
  }

  test('file-read errors and metadata allowlist never log local paths or content', () async {
    await expectLater(traceMomentUpload('read_media', () async {
      throw StateError('/private/file.jpg private-message');
    }), throwsStateError);
    logMomentUpload('test', {'token': 'private-token', 'filename': 'private-file.jpg',
      'body': {'message': 'private-message'}, 'stage': 'read_media'});
    final output = logs.join('\n');
    expect(output, contains('"stage":"read_media"'));
    expect(output, contains('"errorType":"StateError"'));
    for (final secret in ['/private/file.jpg', 'private-token', 'private-file.jpg', 'private-message']) {
      expect(output, isNot(contains(secret)));
    }
  });
}
