import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/utils/server_time_manager.dart';
import 'package:vera/features/home/domain/entities/moment.dart';
import 'package:vera/features/home/presentation/pages/unlocked_moment_screen.dart';
import 'package:vera/main.dart';

void main() {
  for (final scenario in ['creator', 'recipient', 'creator-existing', 'creator-empty', 'recipient-error', 'creator-list-error']) {
    final creator = !scenario.startsWith('recipient');
    final sendError = scenario == 'recipient-error';
    final existing = scenario == 'creator-existing';
    final empty = scenario == 'creator-empty';
    final listError = scenario == 'creator-list-error';
    testWidgets('$scenario conversation never creates a self-thread', (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final threadBodies = <Map<String, dynamic>>[];
      final sentPaths = <String>[];
      var conversationReads = 0;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        initialAuthToken: 'test-token',
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.contains('/chat/') && request.method == 'GET') conversationReads++;
          if (path.endsWith('/profile')) {
            return http.Response(jsonEncode({'id': creator ? 'creator' : 'recipient', 'displayName': creator ? 'Author' : 'Reader'}), 200);
          }
          if (path.endsWith('/content')) {
            return http.Response(jsonEncode({
              'id': 'moment', 'creatorId': 'creator', 'status': 'PUBLISHED',
              'recipientUserIds': empty ? [] : ['creator', 'recipient'],
              'contentType': 'TEXT', 'hasMedia': false, 'message': 'A moment',
            }), 200);
          }
          if (path == '/api/v1/chat/threads') {
            expect(creator, isTrue);
            expect(request.url.queryParameters['box'], 'SENT');
            expect(request.url.queryParameters['limit'], '20');
            if (listError) return http.Response('{"message":"Service unavailable"}', 503);
            return http.Response(jsonEncode({'items': existing ? [
              {'id': 'thread', 'momentId': 'moment', 'creatorUserId': 'creator',
               'recipientUserId': 'recipient', 'recipient': {'displayName': 'Reader'}},
              {'id': 'unrelated', 'momentId': 'another-moment', 'recipientUserId': 'other'},
            ] : []}), 200);
          }
          if (path == '/api/v1/chat/moments/moment/thread') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            threadBodies.add(body);
            expect(body['recipientUserId'], creator ? 'recipient' : null);
            return http.Response('{"id":"thread","momentId":"moment"}', 201);
          }
          if (path == '/api/v1/chat/threads/thread/messages') {
            if (request.method == 'POST') {
              sentPaths.add(path);
              if (sendError) return http.Response('{"message":"Please try again later"}', 503);
              return http.Response('{"id":"message","content":"Hello","senderId":"recipient"}', 201);
            }
            return http.Response('{"items":[]}', 200);
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => ApiClientScope(client: client, child: child!),
        home: const UnlockedMomentScreen(moment: Moment(
          id: 'moment', creatorId: 'creator', userName: 'Author',
          userAvatarUrl: '', timeAgo: '', backgroundImageUrl: '',
          unlockCondition: '', hasMedia: false, contentType: 'TEXT',
        )),
      ));
      await tester.pumpAndSettle();
      final initialReads = conversationReads;
      await tester.pump(const Duration(seconds: 24));
      expect(conversationReads, initialReads, reason: 'Conversation must not poll in the background');
      if (listError) {
        expect(find.text('Could not load the conversation. Please retry.'), findsOneWidget);
        expect(find.text('Recipient conversations will appear here when someone replies.'), findsNothing);
        await tester.ensureVisible(find.text('Retry conversation'));
        await tester.tap(find.text('Retry conversation'));
        await tester.pumpAndSettle();
        expect(conversationReads, initialReads + 1);
        await tester.pumpWidget(const SizedBox.shrink());
        ServerTimeManager.instance.dispose();
        return;
      }
      if (empty) {
        expect(threadBodies, isEmpty);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Recipient conversations will appear here when someone replies.'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        ServerTimeManager.instance.dispose();
        return;
      }
      if (creator) {
        expect(threadBodies, isEmpty);
        expect(find.byType(TextField), findsNothing);
        await tester.ensureVisible(find.byKey(const ValueKey('conversation-recipient')));
        await tester.tap(find.byKey(const ValueKey('conversation-recipient')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(existing ? 'Reader' : 'Recipient 1').last);
        await tester.pumpAndSettle();
      }
      expect(threadBodies, hasLength(existing ? 0 : 1));
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byKey(const ValueKey('send-moment-reply')));
      await tester.pumpAndSettle();
      expect(sentPaths, hasLength(1));
      expect(threadBodies, hasLength(existing ? 0 : 1), reason: 'Reuse the chosen conversation');
      expect(find.textContaining('ApiException'), findsNothing);
      if (sendError) {
        expect(find.text('Could not send reply'), findsOneWidget);
        expect(find.text('Please try again later'), findsOneWidget);
        expect(find.text('Hello'), findsOneWidget, reason: 'Keep the draft after a failed send');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      ServerTimeManager.instance.dispose();
    });
  }
}
