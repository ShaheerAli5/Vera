import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/auth/auth_diagnostics.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/network/api_exception.dart';

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

  test('verification logs HTTP status but never OTP, email or response tokens', () async {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      initialAuthToken: 'saved-secret',
      httpClient: MockClient((request) async {
        expect(jsonDecode(request.body)['code'], '123456');
        return http.Response(jsonEncode({
          'accessToken': 'response-secret',
          'user': {'email': 'private@example.com', 'role': 'user'},
        }), 201);
      }),
    );
    addTearDown(client.close);
    final result = await client.post('/auth/verify-email', body: {
      'email': 'private@example.com', 'code': '123456',
    });
    expect((result as Map)['accessToken'], 'response-secret');
    final output = logs.join('\n');
    expect(output, contains('[AUTH_FLOW] http_request'));
    expect(output, contains('"httpStatus":201'));
    expect(output, contains('"hasAccessToken":true'));
    for (final secret in ['123456', 'private@example.com', 'saved-secret', 'response-secret']) {
      expect(output, isNot(contains(secret)));
    }
  });

  test('denial status is visible without logging backend error bodies', () async {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      httpClient: MockClient((_) async => http.Response(
        '{"message":"Access denied private@example.com code 123456"}', 403,
      )),
    );
    addTearDown(client.close);
    await expectLater(client.post('/auth/verify-email'), throwsA(isA<ApiException>()));
    final output = logs.join('\n');
    expect(output, contains('"httpStatus":403'));
    expect(output, isNot(contains('private@example.com')));
    expect(output, isNot(contains('123456')));
  });

  test('metadata allowlist and role normalization prevent raw credential logging', () {
    logAuthFlow('otp_verified', {
      'savedRole': diagnosticRole(null), 'responseRole': diagnosticRole('ADMIN'),
      'code': '123456', 'email': 'private@example.com', 'token': 'secret',
      'body': {'password': 'private-password'},
    });
    final output = logs.single;
    expect(output, contains('"savedRole":"missing"'));
    expect(output, contains('"responseRole":"owner"'));
    for (final secret in ['123456', 'private@example.com', 'secret', 'private-password']) {
      expect(output, isNot(contains(secret)));
    }
    expect(diagnosticRole('unexpected-secret'), 'unknown');
  });
}
