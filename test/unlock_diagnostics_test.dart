import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/network/api_exception.dart';
import 'package:vera/features/home/data/datasources/moments_remote_data_source.dart';

void main() {
  test('GPS proof is serialized as bounded-precision numbers, preserving metadata', () async {
    final capturedAt = DateTime.now().toUtc();
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['latitude'], 24.860735);
        expect(body['longitude'], 67.001137);
        expect(body['accuracyM'], 12.345678901);
        expect(body['latitude'], isA<num>());
        expect(body['longitude'], isA<num>());
        expect(body['accuracyM'], isA<num>());
        expect(body['capturedAt'], capturedAt.toIso8601String());
        expect(body['isMocked'], isFalse);
        return http.Response('{"id":"test-moment","status":"PUBLISHED"}', 201);
      }),
    );
    addTearDown(client.close);
    await MomentsRemoteDataSource(client).unlockMoment(
      momentId: 'test-moment',
      latitude: 24.86073512345,
      longitude: 67.00113698765,
      accuracyM: 12.345678901,
      capturedAt: capturedAt,
      isMocked: false,
    );
  });

  test('invalid GPS values are rejected before sending a request', () async {
    var calls = 0;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      httpClient: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);
    final source = MomentsRemoteDataSource(client);
    for (final proof in [
      [double.nan, 67.0, 12.0],
      [24.0, double.infinity, 12.0],
      [91.0, 67.0, 12.0],
      [24.0, -181.0, 12.0],
      [24.0, 67.0, -1.0],
    ]) {
      await expectLater(
        source.unlockMoment(momentId: 'test', latitude: proof[0], longitude: proof[1], accuracyM: proof[2]),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_location_proof')),
      );
    }
    expect(calls, 0);
  });

  test('approval failures have distinct diagnostics and preserve the API error', () async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      httpClient: MockClient((request) async {
        expect(request.body, '{"version":3}');
        return http.Response(
          '{"code":"VERSION_CONFLICT","message":"Please reload the moment"}',
          409,
        );
      }),
    );
    addTearDown(client.close);
    await expectLater(
      client.post('/admin/moments/test-moment/approve', body: {'version': 3}),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
    final output = logs.join('\n');
    expect(output, contains('[ADMIN_APPROVAL] request'));
    expect(output, contains('"httpStatus":409'));
    expect(output, contains('VERSION_CONFLICT'));
    expect(output, isNot(contains('[MOMENT_UNLOCK]')));
  });

  test('unlock logs HTTP errors and proof presence without sensitive values', () async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      initialAuthToken: 'private-access-token',
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer private-access-token');
        expect(request.body, contains('24.860735'));
        return http.Response(
          '{"code":"OUTSIDE_RADIUS","message":"Outside radius: latitude=24.860735 longitude=67.001137 Bearer private-access-token password=secret"}',
          422,
        );
      }),
    );
    addTearDown(client.close);
    await expectLater(
      MomentsRemoteDataSource(client).unlockMoment(
        momentId: 'test-moment',
        latitude: 24.860735,
        longitude: 67.001137,
        accuracyM: 12.4,
        capturedAt: DateTime.now().toUtc(),
        isMocked: false,
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 422)),
    );
    final output = logs.join('\n');
    expect(output, contains('[MOMENT_UNLOCK] request'));
    expect(output, contains('"hasCoordinates":true'));
    expect(output, contains('"httpStatus":422'));
    expect(output, contains('OUTSIDE_RADIUS'));
    for (final sensitive in ['24.860735', '67.001137', 'private-access-token', 'secret']) {
      expect(output, isNot(contains(sensitive)));
    }
  });
}
