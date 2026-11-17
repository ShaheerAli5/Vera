import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/network/api_exception.dart';
import 'package:vera/features/splash/presentation/pages/splash_screen.dart';
import 'package:vera/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ApiClient clientWith(Future<http.Response> Function(http.Request) handler) {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      httpClient: MockClient(handler),
    );
    addTearDown(client.close);
    return client;
  }

  Future<void> seed(ApiClient client) => client.setTokens(
    authToken: 'access',
    refreshToken: 'refresh',
    userRole: 'user',
  );

  test('role-only updates preserve tokens in memory and storage', () async {
    final client = clientWith((_) async => http.Response('{}', 200));
    await seed(client);
    await client.setTokens(userRole: 'owner');
    await client.initFromStorage();
    expect(client.authToken, 'access');
    expect(client.refreshToken, 'refresh');
    expect(client.userRole, 'owner');
    await client.clearTokens();
    await client.initFromStorage();
    expect(client.authToken, isNull);
    expect(client.refreshToken, isNull);
    expect(client.userRole, isNull);
  });

  test(
    'expired access token refreshes and retries once with new token',
    () async {
      var profileCalls = 0;
      var refreshCalls = 0;
      final client = clientWith((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          return http.Response(
            jsonEncode({
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
            }),
            200,
          );
        }
        profileCalls++;
        if (profileCalls == 1) return http.Response('{}', 401);
        expect(request.headers['Authorization'], 'Bearer new-access');
        return http.Response('{"role":"user"}', 200);
      });
      await seed(client);
      expect(await client.get('/profile'), {'role': 'user'});
      expect(profileCalls, 2);
      expect(refreshCalls, 1);
      await client.initFromStorage();
      expect(client.authToken, 'new-access');
      expect(client.refreshToken, 'new-refresh');
    },
  );

  test('rejected refresh credentials clear the session', () async {
    final client = clientWith(
      (request) async => http.Response(
        '{}',
        request.url.path.endsWith('/auth/refresh') ? 403 : 401,
      ),
    );
    await seed(client);
    await expectLater(client.get('/profile'), throwsA(isA<ApiException>()));
    await client.initFromStorage();
    expect(client.authToken, isNull);
    expect(client.refreshToken, isNull);
    expect(client.userRole, isNull);
  });

  test(
    'temporary refresh failure preserves session and is not a terminal 401',
    () async {
      final client = clientWith(
        (request) async => http.Response(
          '{}',
          request.url.path.endsWith('/auth/refresh') ? 503 : 401,
        ),
      );
      await seed(client);
      await expectLater(
        client.get('/profile'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'session_refresh_unavailable',
          ),
        ),
      );
      await client.initFromStorage();
      expect(client.authToken, 'access');
      expect(client.refreshToken, 'refresh');
    },
  );

  for (final offline in [true, false]) {
    testWidgets(
      'startup preserves session and allows retry on ${offline ? 'offline' : 'server error'}',
      (tester) async {
        var calls = 0;
        final client = clientWith((_) async {
          calls++;
          if (offline) throw http.ClientException('offline');
          return http.Response('{}', 503);
        });
        await seed(client);
        await tester.pumpWidget(
          MaterialApp(
            home: ApiClientScope(client: client, child: const SplashScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Unable to connect'), findsOneWidget);
        expect(client.authToken, 'access');
        expect(client.refreshToken, 'refresh');
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(calls, 2);
        expect(find.text('Unable to connect'), findsOneWidget);
        await client.initFromStorage();
        expect(client.authToken, 'access');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
