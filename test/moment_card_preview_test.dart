import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/home/data/models/moment_model.dart';
import 'package:vera/features/home/presentation/widgets/moment_card.dart';
import 'package:vera/main.dart';

import 'support/fake_moment_socket.dart';

void main() {
  test('locked preview remains separate from protected media through updates', () {
    final moment = MomentModel.fromJson({
      'id': 'post',
      'visibility': 'PUBLIC',
      'creator': {'displayName': 'John Travolta', 'avatarUrl': '/avatar.jpg'},
      'createdAt': '2026-11-20T09:00:00Z',
      'clueCoverImageUrl': '/clues/post.jpg',
      'mediaUrl': 'https://example.com/private-original.jpg',
      'availability': {'isApproved': true, 'isUnlocked': false},
    }).toEntity();
    expect(moment.clueCoverImageUrl, '/clues/post.jpg');
    expect(moment.backgroundImageUrl, isEmpty);
    expect(moment.userName, 'John Travolta');
    expect(moment.userAvatarUrl, endsWith('/avatar.jpg'));
    expect(moment.copyWith(status: 'REJECTED').clueCoverImageUrl, '/clues/post.jpg');
    expect(moment.canAccessContent, isFalse);
    final withoutClue = MomentModel.fromJson({
      'id': 'post',
      'mediaUrl': 'https://example.com/private-original.jpg',
      'availability': {'isUnlocked': false},
    }).toEntity();
    expect(withoutClue.clueCoverImageUrl, isEmpty);
    expect(withoutClue.backgroundImageUrl, isEmpty);
    ServerTimeManager.instance.dispose();
  });

  test('backend creator, UTC dates and both location aliases map consistently', () {
    final now = DateTime.now().toUtc();
    ServerTimeManager.instance.updateServerTime(now);
    final created = now.subtract(const Duration(hours: 2));
    final published = now.subtract(const Duration(hours: 1));
    for (final key in ['unlockRule', 'unlock']) {
      final model = MomentModel.fromJson({'data': {
        'id': 'post',
        'creator': {'id': 'author', 'displayName': 'Sam Rivera',
          'username': 'sam', 'avatarUrl': 'https://example.com/sam.jpg'},
        'createdAt': created.toIso8601String(),
        'publishedAt': published.toIso8601String(),
        'timeAgo': 'Just now',
        'availability': {'isApproved': true, 'isUnlocked': false},
        key: {'type': 'LOCATION', 'placeName': '', 'locationName': 'Tokyo Tower',
          'radiusM': 150.0, 'radius': 200},
      }});
      final moment = model.toEntity();
      expect(moment.userName, 'Sam Rivera');
      expect(moment.creatorId, 'author');
      expect(moment.userAvatarUrl, 'https://example.com/sam.jpg');
      expect(moment.createdAt, created);
      expect(moment.publishedAt, published);
      expect(moment.timeAgo, '2h ago');
      expect(moment.unlockPlaceName, 'Tokyo Tower');
      expect(moment.unlockRadiusM, 150);
      expect(moment.unlockCondition, "Opens when you're at Tokyo Tower");
      expect(moment.canAccessContent, isFalse);
      expect(moment.copyWith(status: 'REJECTED').createdAt, created);
    }
    final fallback = MomentModel.fromJson({
      'id': 'fallback',
      'creator': {'displayName': ' ', 'username': 'sam'},
      'publishedAt': published.toIso8601String(),
    }).toEntity();
    expect(fallback.userName, 'sam');
    expect(fallback.timeAgo, '1h ago');
    ServerTimeManager.instance.dispose();
  });

  testWidgets('locked cards use the local PNG background behind creator details', (tester) async {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
      initialAuthToken: 'test',
      momentSocketFactory: (url, options) => FakeMomentSocket(),
      httpClient: MockClient((_) async => http.Response(
        '{"id":"reader","displayName":"Reader"}', 200,
      )),
    );
    addTearDown(client.close);
    var moment = MomentModel.fromJson({
      'id': 'post',
      'visibility': 'PUBLIC',
      'status': 'PUBLISHED',
      'creator': {'id': 'author', 'displayName': 'John Travolta'},
      'timeAgo': '2h ago',
      'clueCoverImageUrl': '/clues/post.jpg',
      'availability': {'isApproved': true, 'isUnlocked': false},
    }).toEntity();
    Future<void> showCard({bool sent = false}) => tester.pumpWidget(MaterialApp(
      builder: (context, child) => ApiClientScope(client: client, child: child!),
      home: Scaffold(body: Center(child: SizedBox(width: 343, child: MomentCard(
        moment: moment, scale: 1, showModerationStatus: sent,
      )))),
    ));
    await showCard();
    await tester.pump();
    expect(find.text('John Travolta'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
    expect(find.text('Published'), findsNothing);
    final background = tester.widget<Image>(find.byKey(const ValueKey('moment-card-locked-cover')));
    expect(background.image, isA<AssetImage>());
    expect((background.image as AssetImage).assetName, 'assets/images/blur bg.png');
    expect(background.fit, BoxFit.cover);
    expect(tester.widgetList<Image>(find.byType(Image)).where((image) => image.image is NetworkImage), isEmpty);
    expect(find.byKey(const ValueKey('moment-card-locked')), findsOneWidget);
    await showCard(sent: true);
    await tester.pump();
    expect(find.text('John Travolta'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
    expect(find.text('To Everyone (public)'), findsNothing);
    expect(find.text('Published'), findsOneWidget);
    moment = moment.copyWith(clueCoverImageUrl: '');
    await showCard();
    await tester.pump();
    expect(find.byKey(const ValueKey('moment-card-locked-cover')), findsOneWidget);
    expect(tester.widget<Image>(find.byKey(const ValueKey('moment-card-locked-cover'))).image, isA<AssetImage>());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    ServerTimeManager.instance.dispose();
  });
}
