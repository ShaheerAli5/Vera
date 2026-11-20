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
import 'package:vera/features/account/presentation/pages/sign_in_screen.dart';
import 'package:vera/features/admin/presentation/pages/admin_main_screen.dart';
import 'package:vera/features/home/presentation/pages/home_screen.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

void main() {
  for (final scenario in ['user', 'admin', 'owner', 'profile_fallback', 'unknown', 'no_token', 'invalid_password']) {
    testWidgets('main sign-in handles $scenario without Admin Access', (tester) async {
      tester.view.physicalSize = const Size(600, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final logs = <String>[];
      final previousPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = previousPrint);
      var profileCalls = 0;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        momentSocketFactory: (_, options) => FakeMomentSocket(),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/login')) {
            if (scenario == 'invalid_password') return http.Response('{"message":"Invalid credentials"}', 401);
            return http.Response(jsonEncode({
              if (scenario != 'no_token') 'accessToken': 'fake-access',
              'refreshToken': 'fake-refresh',
              'user': {'id': 'reader',
                if (scenario != 'profile_fallback') 'role': scenario == 'no_token' ? 'user' : scenario,
              },
            }), 200);
          }
          if (request.url.path.endsWith('/profile')) {
            profileCalls++;
            return http.Response('{"id":"reader","role":"user","displayName":"Reader"}', 200);
          }
          return http.Response('{"items":[]}', 200);
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [momentRouteObserver],
        builder: (_, child) => ApiClientScope(client: client, child: child!),
        home: const SignInScreen(),
      ));
      expect(find.text('Admin Access'), findsNothing);
      await tester.enterText(find.byType(TextField).at(0), 'private@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'private-password');
      tester.testTextInput.hide();
      await tester.ensureVisible(find.text('Sign in'));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      final isAdmin = scenario == 'admin' || scenario == 'owner';
      final success = isAdmin || scenario == 'user' || scenario == 'profile_fallback';
      if (success) {
        expect(find.byType(isAdmin ? AdminMainScreen : HomeScreen), findsOneWidget);
        expect(client.userRole, isAdmin ? 'owner' : 'user');
        await client.initFromStorage();
        expect(client.userRole, isAdmin ? 'owner' : 'user');
        expect(client.authToken, 'fake-access');
        expect(logs.join('\n'), contains('"destination":"${isAdmin ? 'admin' : 'home'}"'));
        if (scenario != 'profile_fallback') expect(profileCalls, 0);
      } else {
        expect(find.byType(SignInScreen), findsOneWidget);
        expect(find.byType(AdminMainScreen), findsNothing);
        expect(find.byType(HomeScreen), findsNothing);
        expect(client.userRole, isNull);
        expect(logs.join('\n'), contains('[AUTH_FLOW] login_failed'));
      }
      for (final secret in ['fake-access', 'fake-refresh', 'private@example.com', 'private-password']) {
        expect(logs.join('\n'), isNot(contains(secret)));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
      debugPrint = previousPrint;
    });
  }
}
