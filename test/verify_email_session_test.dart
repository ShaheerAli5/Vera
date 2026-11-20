import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/realtime/moment_realtime_route.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/account/data/models/verify_email_result.dart';
import 'package:vera/features/account/presentation/pages/sign_in_screen.dart';
import 'package:vera/features/account/presentation/pages/verify_email_screen.dart';
import 'package:vera/features/home/presentation/pages/home_screen.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

void main() {
  test('verification parses the role in direct and nested responses', () {
    for (final nested in [false, true]) {
      final payload = {
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'user': {'id': 'reader', 'role': 'user'},
      };
      final result = VerifyEmailResult.fromJson(
        nested ? {'data': payload} : payload,
      );
      expect(result.user?.role, 'user');
      expect(result.token, 'access');
    }
  });

  for (final scenario in [
    'response_role',
    'profile_role',
    'invalid_role',
    'no_token',
  ]) {
    testWidgets('OTP session: $scenario', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      var homeRequests = 0;
      bool? profileAuthenticated;
      late final ApiClient client;
      client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        momentSocketFactory: (_, options) => FakeMomentSocket(),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/verify-email')) {
            return http.Response(
              jsonEncode({
                'message': 'Verified',
                if (scenario != 'no_token') ...{
                  'accessToken': 'access',
                  'refreshToken': 'refresh',
                },
                'user': {
                  'id': 'reader',
                  if (scenario == 'response_role') 'role': 'user',
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/profile')) {
            profileAuthenticated = request.headers.values.contains(
              'Bearer access',
            );
            return http.Response(
              jsonEncode({
                'id': 'reader',
                'displayName': 'Reader',
                if (scenario != 'invalid_role') 'role': 'user',
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/home/feed')) {
            homeRequests++;
            expect(client.userRole, 'user');
          }
          return http.Response('{"items":[]}', 200);
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [momentRouteObserver],
          builder: (_, child) => ApiClientScope(client: client, child: child!),
          home: const VerifyEmailScreen(email: 'test@example.com'),
        ),
      );
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pumpAndSettle();
      if (scenario == 'no_token') {
        expect(find.byType(SignInScreen), findsOneWidget);
        expect(homeRequests, 0);
      } else if (scenario == 'invalid_role') {
        expect(find.byType(HomeScreen), findsNothing);
        expect(homeRequests, 0);
        expect(client.userRole, isNull);
      } else {
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(homeRequests, greaterThan(0));
        expect(client.userRole, 'user');
        if (scenario == 'profile_role') expect(profileAuthenticated, isTrue);
        expect(client.authToken, 'access');
        expect(find.text('Access Denied'), findsNothing);
        await client.initFromStorage();
        expect(client.userRole, 'user');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
    });
  }
}
