import 'package:flutter_test/flutter_test.dart';
import 'package:vera/core/realtime/admin_moderation_update.dart';
import 'package:vera/core/realtime/moment_realtime_service.dart';

import 'support/fake_moment_socket.dart';

Map<String, dynamic> counts(
  int pending, [
  int approved = 31,
  int rejected = 4,
]) => {'pendingReview': pending, 'approved': approved, 'rejected': rejected};

void main() {
  test(
    'admin-only demand connects an empty queue and subscriptions are reference counted',
    () {
      final socket = FakeMomentSocket();
      var creations = 0;
      final service = MomentRealtimeService(
        baseUrl: 'https://vera.aptechmedia.com',
        token: 'access',
        socketFactory: (url, options) {
          creations++;
          expect(url, 'https://vera.aptechmedia.com/moments');
          expect(options['auth'], {'token': 'access'});
          expect(options['path'], '/socket.io');
          return socket;
        },
      );
      addTearDown(service.dispose);
      service.subscribeModeration();
      service.subscribeModeration();
      expect(creations, 1);
      socket.receive('connect');
      expect(socket.emissions.map((e) => e.$1), ['admin:moderation:subscribe']);
      service.unsubscribeModeration();
      expect(socket.emissions.length, 1);
      expect(socket.disposed, isFalse);
      service.unsubscribeModeration();
      expect(socket.emissions.last.$1, 'admin:moderation:unsubscribe');
      expect(socket.disposed, isTrue);
    },
  );

  test(
    'reconnect and access-token rotation restore the admin subscription',
    () {
      final sockets = <FakeMomentSocket>[];
      final options = <Map<String, dynamic>>[];
      final service = MomentRealtimeService(
        baseUrl: 'https://example.com',
        token: 'old',
        socketFactory: (url, config) {
          options.add(config);
          final socket = FakeMomentSocket();
          sockets.add(socket);
          return socket;
        },
      );
      addTearDown(service.dispose);
      service.subscribeModeration();
      final old = sockets.single;
      old.receive('connect');
      old.receive('connect');
      expect(old.emissions.map((e) => e.$1), [
        'admin:moderation:subscribe',
        'admin:moderation:subscribe',
      ]);
      service.updateToken('new');
      expect(old.disposed, isTrue);
      expect(options.last['auth'], {'token': 'new'});
      sockets.last.receive('connect');
      expect(sockets.last.emissions.single.$1, 'admin:moderation:subscribe');
      old.receive('admin:moderation:subscribed', {
        'moderationCounts': counts(99),
      });
      expect(
        service.moderationCounts,
        isNull,
        reason: 'Ignore old socket callbacks',
      );
      sockets.last.receive('admin:moderation:subscribed', {
        'moderationCounts': counts(6),
      });
      expect(service.moderationCounts?.pendingReview, 6);
      service.updateToken(null);
      expect(sockets.last.disposed, isTrue);
      expect(service.moderationCounts, isNull);
    },
  );

  test(
    'initial snapshot and all transitions work; named and generic duplicates apply once',
    () {
      final socket = FakeMomentSocket();
      final service = MomentRealtimeService(
        baseUrl: 'https://example.com',
        token: 'test',
        socketFactory: (_, options) => socket,
      );
      addTearDown(service.dispose);
      final received = <AdminModerationUpdate>[];
      final sub = service.moderationUpdates.listen(received.add);
      addTearDown(sub.cancel);
      service.subscribeModeration();
      socket.receive('admin:moderation:subscribed', {
        'moderationCounts': counts(6),
        'serverTime': '2026-11-20T09:15:00Z',
      });
      expect(received.length, 1);
      final transitions = ['SUBMITTED', 'APPROVED', 'REJECTED', 'DELETED'];
      for (var i = 0; i < transitions.length; i++) {
        final payload = {
          'momentId': 'post',
          'transition': transitions[i],
          'version': i + 1,
          'moderationCounts': counts(5 - i),
          'serverTime': '2026-11-20T09:15:0${i + 1}Z',
        };
        socket.receive(
          'admin:moderation:${transitions[i].toLowerCase()}',
          payload,
        );
        socket.receive('admin:moderation:update', payload);
      }
      expect(received.length, 5);
      expect(service.moderationState('post')?.transition, 'DELETED');
      expect(service.moderationCounts?.pendingReview, 2);
      socket.receive('admin:moderation:submitted', {
        'momentId': 'post',
        'version': 1,
        'moderationCounts': counts(99),
      });
      expect(received.length, 5);
      expect(service.moderationState('post')?.transition, 'DELETED');
      expect(
        service.latest('post'),
        isNull,
        reason: 'Moderation cannot modify recipient availability',
      );
      // A delayed snapshot must not replace newer totals.
      socket.receive('admin:moderation:subscribed', {
        'moderationCounts': counts(99),
        'serverTime': '2026-11-20T09:14:59Z',
      });
      expect(service.moderationCounts?.pendingReview, 2);
    },
  );

  test(
    'unsubscribing admin preserves private watches and ignores later admin events',
    () {
      final socket = FakeMomentSocket();
      final service = MomentRealtimeService(
        baseUrl: 'https://example.com',
        token: 'test',
        socketFactory: (_, options) => socket,
      );
      addTearDown(service.dispose);
      service.watch('private');
      socket.receive('connect');
      expect(socket.emissions.any((e) => e.$1.startsWith('admin:')), isFalse);
      socket.receive('admin:moderation:subscribed', {
        'moderationCounts': counts(6),
      });
      expect(service.moderationCounts, isNull);
      service.subscribeModeration();
      service.unsubscribeModeration();
      expect(socket.disposed, isFalse);
      socket.receive('admin:moderation:submitted', {
        'momentId': 'post',
        'version': 1,
        'moderationCounts': counts(6),
      });
      expect(service.moderationCounts, isNull);
      service.unwatch('private');
      expect(socket.disposed, isTrue);
    },
  );

  test(
    'HTTP count reconciliation advances old snapshots but preserves newer socket counts',
    () {
      final socket = FakeMomentSocket();
      final service = MomentRealtimeService(
        baseUrl: 'https://example.com',
        token: 'test',
        socketFactory: (_, options) => socket,
      );
      addTearDown(service.dispose);
      service.subscribeModeration();
      socket.receive('connect');
      socket.receive('admin:moderation:subscribed', {
        'moderationCounts': counts(0),
      });
      final revision = service.moderationRevision;
      final fresh = service.reconcileModerationCounts(
        const ModerationCounts(pendingReview: 2, approved: 31, rejected: 4),
        revision,
      );
      expect(fresh.pendingReview, 2);
      expect(service.moderationCounts?.pendingReview, 2);
      final before = service.moderationRevision;
      socket.receive('admin:moderation:submitted', {
        'momentId': 'new',
        'version': 1,
        'moderationCounts': counts(3),
      });
      expect(
        service
            .reconcileModerationCounts(
              const ModerationCounts(
                pendingReview: 2,
                approved: 31,
                rejected: 4,
              ),
              before,
            )
            .pendingReview,
        3,
      );
    },
  );

  test(
    'retry unacknowledged subscriptions without retrying an acknowledged feed',
    () {
      final socket = FakeMomentSocket();
      final service = MomentRealtimeService(
        baseUrl: 'https://example.com',
        token: 'test',
        socketFactory: (_, options) => socket,
      );
      addTearDown(service.dispose);
      service.subscribeModeration();
      socket.receive('connect');
      expect(service.moderationFeedConfirmed, isFalse);
      service.ensureModerationSubscription();
      expect(socket.emissions.length, 2);
      socket.receive('admin:moderation:subscribed', {
        'moderationCounts': counts(0),
      });
      expect(service.moderationFeedConfirmed, isTrue);
      service.ensureModerationSubscription();
      expect(socket.emissions.length, 2);
      socket.receive('disconnect');
      expect(service.moderationFeedConfirmed, isFalse);
    },
  );

  test('invalid transitions and malformed count snapshots are ignored', () {
    expect(
      AdminModerationUpdate.parse('admin:moderation:subscribed', {
        'moderationCounts': counts(-1),
      }),
      isNull,
    );
    expect(
      AdminModerationUpdate.parse('admin:moderation:update', {
        'momentId': 'post',
        'transition': 'UNKNOWN',
      }),
      isNull,
    );
    expect(
      AdminModerationUpdate.parse('admin:moderation:submitted', {
        'momentId': 42,
      }),
      isNull,
    );
    expect(
      AdminModerationUpdate.parse('admin:moderation:subscribed', {
        'moderationCounts': {
          'pendingReview': '6',
          'approved': 31,
          'rejected': 4,
        },
      }),
      isNull,
    );
    expect(
      AdminModerationUpdate.parse('admin:moderation:subscribed', 'invalid'),
      isNull,
    );
  });
}
