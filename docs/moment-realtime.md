# Moment realtime updates

The API client owns a lazy Socket.IO session. The production connection uses
`https://vera.aptechmedia.com/moments`, path `/socket.io`, WebSocket transport,
and `auth: {token: accessToken}`. An `API_BASE_URL` override also changes the
socket origin, while retaining the namespace and path.

Moment cards, user locked/unlocked details, and both admin review screens watch their moment
while visible. Navigating away emits `moment:unwatch` with the moment ID;
returning or reconnecting emits `moment:watch` again. Dialogs retain the watch.
Private watches and admin-feed subscriptions use reference counts. The last
consumer releases the shared connection.

All six requested events are handled: `moment:status`, `moment:submitted`,
`moment:approved`, `moment:rejected`, `moment:unlocked`, `moment:deleted`.
Expected payload identity is `momentId` (or `id`); `data` and `moment` wrappers
are supported. The unlock flag must be a JSON boolean under
`availability.isUnlocked`. Event names and approval never grant access.
Missing flags preserve previous availability; explicit false overrides local
timestamps and delayed API responses. Deleted moments hide their content.
Loaded home lists consume the same updates so returning to the feed preserves
status and removes deleted items. Card moderation subtitles are derived from
current status and invitation state, rather than retaining the label from the
original API response. Approval and rejection therefore update sender-card
badges without opening the detail route or issuing another API request.

API token rotation disposes the old socket and creates a fresh manager with the
new access token. Watched rooms are restored on connect. Logout clears cached
socket state and disconnects. Debug logs use `[MOMENT_REALTIME]` and contain only
event names, with no token, post content, or raw server errors.

The full suite passes 73 tests. Realtime tests use a fake socket and cover transport configuration, room lifecycle,
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

The active admin tab emits `admin:moderation:subscribe` on the existing
`/moments` connection, even when the pending queue is empty. Each reconnect or
access-token rotation restores this subscription. Leaving moderation tabs,
covering the admin route, entering the background, or disposing the screen
releases the subscription with `admin:moderation:unsubscribe`. Private moment
watches can continue sharing the socket independently.

`admin:moderation:subscribed` supplies the initial `moderationCounts` and
`serverTime`. The client handles named `submitted`, `approved`, `rejected`, and
`deleted` events plus the alternative `admin:moderation:update`. Matching
moment/version/transition duplicates are applied once; older moment versions
are ignored. Older timestamped count snapshots cannot replace newer totals.
No admin event grants recipient access to private content.

Dashboard badges replace pending/approved/rejected values directly from
`moderationCounts`. All mounted moderation tabs retain these updates, including
hidden local lists. Approved, rejected, and deleted rows leave the pending queue
immediately. Submitted events trigger a debounced, serialized fetch of the
pending list, preserving its current search query and obtaining full records.
A bounded transition ledger prevents stale in-flight API responses from
reintroducing moderated rows; a newer resubmission version remains eligible.

Socket events provide immediate updates. No periodic dashboard or queue refresh
runs. Entry, route return, resume, reconnect, and transition events synchronize
full API records. Manual pull-to-refresh and both refresh buttons remain available.

Cached socket totals do not override every future API response. Fresh queue
pagination totals reconcile pending badges (even if `/admin/stats` reports an
outdated zero), unless a newer socket event arrived during the read. Missing
stats fields preserve known values instead of inventing zero. Reconciled totals
also update hidden moderation tabs. Stale moderated rows remain filtered out. Server-side role,
active-status, and deletion checks authorize the admin feed. Logs contain only
`[ADMIN_MODERATION]` delivery metadata, without tokens or payload contents.
`subscribe_sent` confirms the client emitted the request;
`admin:moderation:subscribed` confirms the acknowledgement. `payload_rejected`
identifies a contract mismatch. Connection errors report a safe category;
`http_counts_reconciled` and `pending_totals_disagree` identify count
reconciliation and inconsistent backend totals. A transport `connected` log
alone does not confirm that the admin subscription was acknowledged.

Regression tests cover empty-queue submission discovery, initial counts, all
transitions, duplicate delivery, stale responses, shared socket lifetime,
reconnects, token rotation, logout, background pausing, and slow requests.

## Private invitation access contract

Received moments are loaded from `/moments/inbox?page=1&limit=20`. Invitation
state gates access: pending and declined invitations cannot open content or
call `/unlock`. Acceptance and decline POSTs have no body. An accepted response
with `isUnlocked: true`, or an unlock timestamp when no explicit flag is supplied,
can open content; an explicit false keeps it locked. `availability.isApproved`
is independent of unlocking and can deny access.

Device time only triggers a status refresh. It never grants access. Inbox reads
run on application resume, socket connection/reconnection, countdown completion,
and foreground Firebase messages. Opening a notification also checks inbox state;
notification text and event names cannot grant access. Moment lookup in the inbox
traverses pagination. A later REST result can replace older socket state, while
socket updates arriving during that request retain priority.

Location unlocking captures a fresh high-accuracy foreground position after
acceptance. Readings two minutes old or more are rejected locally; the provider's
accuracy and mocked flag are forwarded without inventing accuracy. Successful
HTTP status alone does not grant access: responses without unlock state are
confirmed through the inbox. Already-unlocked recipients do not recapture GPS.

Protected content uses `/moments/{id}/content` and
`/moments/{id}/content/media` with bearer authentication. Unconfirmed entry into
the unlocked screen is redirected before protected requests. Locked previews
use a placeholder rather than downloading and blurring the private original.
Unlocked card previews also use the protected media endpoint.
