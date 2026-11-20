import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/features/home/presentation/widgets/creator_avatar.dart';
import 'package:vera/main.dart';

void main() {
  testWidgets('missing avatars show the trimmed, uppercase first letter', (tester) async {
    for (final input in <(String, String?, String)>[
      ('Maaz Khan', null, 'M'),
      ('  faizan ', '', 'F'),
      ('Sam', '   ', 'S'),
      ('', null, '?'),
      ('👩‍💻 Sam', null, '👩‍💻'),
    ]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: CreatorAvatar(
        name: input.$1, avatarUrl: input.$2,
      ))));
      expect(find.text(input.$3), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.getSize(find.byType(CreatorAvatar)), const Size(36, 36));
    }
  });

  testWidgets('initial stays visible during loading and after a failed photo request', (tester) async {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      initialAuthToken: 'test',
    );
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => ApiClientScope(client: client, child: child!),
      home: const Scaffold(body: CreatorAvatar(
        name: 'Maaz Khan', avatarUrl: '/api/v1/discover/users/creator/avatar',
      )),
    ));
    expect(find.text('M'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    // Flutter widget tests reject network images with HTTP 400 by default.
    await tester.pumpAndSettle();
    expect(find.text('M'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
