import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/home/domain/entities/moment.dart';
import 'package:vera/features/home/presentation/pages/locked_moment_screen.dart';
import 'package:vera/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('automatic checks fetch status once while pending and back off on 429', (tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<http.Response>();
    var statusCalls = 0;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      initialAuthToken: 'test',
      httpClient: MockClient((request) async {
        expect(request.method, 'GET', reason: 'Automatic checks must not POST an unlock');
        if (request.url.path.endsWith('/profile')) {
          return http.Response('{"id":"recipient","displayName":"Recipient"}', 200);
        }
        expect(request.url.path, '/api/v1/moments/location-test');
        statusCalls++;
        return pending.future;
      }),
    );
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => ApiClientScope(client: client, child: child!),
      home: const LockedMomentScreen(moment: Moment(
        id: 'location-test',
        creatorId: 'creator',
        userName: 'Creator',
        userAvatarUrl: '',
        timeAgo: '',
        backgroundImageUrl: '',
        unlockCondition: 'At the selected place',
        unlockType: MomentUnlockType.location,
        status: 'PENDING_REVIEW',
        hasMedia: false,
      )),
    ));
    await tester.pump();
    for (var i = 0; i < 35; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(statusCalls, 1);
    pending.complete(http.Response('{"message":"Too Many Requests"}', 429));
    await tester.pump();
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(statusCalls, 1, reason: '429 should pause status polling');
    await tester.pumpWidget(const SizedBox.shrink());
    ServerTimeManager.instance.dispose();
  });
}
