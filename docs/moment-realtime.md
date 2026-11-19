# Moment realtime updates

The API client owns a lazy Socket.IO session. The production connection uses
`https://vera.aptechmedia.com/moments`, path `/socket.io`, WebSocket transport,
and `auth: {token: accessToken}`. An `API_BASE_URL` override also changes the
socket origin, while retaining the namespace and path.

Moment cards, user locked/unlocked details, and both admin review screens watch their moment
while visible. Navigating away emits `moment:unwatch` with the moment ID;
returning or reconnecting emits `moment:watch` again. Dialogs retain the watch.
Shared watches use reference counts. The last watcher releases the connection.

All six requested events are handled: `moment:status`, `moment:submitted`,
`moment:approved`, `moment:rejected`, `moment:unlocked`, `moment:deleted`.
Expected payload identity is `momentId` (or `id`); `data` and `moment` wrappers
are supported. The unlock flag must be a JSON boolean under
`availability.isUnlocked`. Event names and approval never grant access.
Missing flags preserve previous availability; explicit false overrides local
timestamps and delayed API responses. Deleted moments hide their content.
Loaded home lists consume the same updates so returning to the feed preserves
status and removes deleted items.

API token rotation disposes the old socket and creates a fresh manager with the
new access token. Watched rooms are restored on connect. Logout clears cached
socket state and disconnects. Debug logs use `[MOMENT_REALTIME]` and contain only
event names, with no token, post content, or raw server errors.

The full suite passes 44 tests. Realtime tests use a fake socket and cover transport configuration, room lifecycle,
reconnects, API token refresh, malformed/unrelated events, authoritative false,
all six events, screen transitions, and deletion. Run `flutter test`.
Live delivery still needs verification against the deployed server: open a
moment on a device, approve/reject it from another session, then confirm status
updates without a reload. Test unlock and deletion similarly, and repeat after
a network interruption. These tests do not send mutations to production.

Socket updates complement FCM/APNs. They do not provide operating-system push
notifications while the app is terminated.

The dependency lock was resolved with the installed Flutter SDK; SDK-pinned
transitive packages were adjusted by pub along with adding socket_io_client.

## Admin dashboard and queue

The active admin tab reloads on entry, after returning from a review route, and
when the application resumes. Loaded pending IDs are watched for socket events;
these invalidate the active tab's data with a short debounce. New submissions
cannot be discovered through an unknown moment ID: the supplied server contract
has no admin-wide subscription. A 15-second foreground-only read discovers new
pending moments even when the queue is empty. Instant discovery would require a
backend admin-wide event feed.

Reads are serialized and repeated invalidations retain only one follow-up.
Hidden tabs, covered routes, and background apps release watches and stop the
periodic check. Automatic reads preserve visible content. Manual pull-to-refresh,
the queue button beside search, and the dashboard refresh button remain available.
Dashboard pending count uses the stats total, falling back to the queue's total
rather than just the first page length. Admin regression tests cover discovery,
moderation events, tab switching, route return, resume, totals, and slow requests.
