# Notification investigation — 19 November 2026

## Confirmed observations

- Connected Android debug phone: POST_NOTIFICATIONS granted, notification channel
  `vera_moments_channel` has importance 4, package not force-stopped, FCM receiver
  and service present.
- Android native Firebase configuration and Dart Firebase options both point to
  project `vera-2a46c`, sender `615422190489`.
- With explicit user authorization, read-only checks confirmed saved login and
  cached FCM tokens exist. Values were not displayed or saved to diagnostic files.
- The signed-in account's `/profile/settings` reports pushEnabled,
  pushInvitations, pushUnlocks, and pushReplies all true.
- `/notifications?page=1&limit=20` returns HTTP 400 with
  `property page should not exist`.
- `/notifications?limit=20` returns HTTP 200 with items/nextCursor/hasMore.
  The tested account currently has zero returned notification records and an
  unread count of zero. This snapshot does not prove whether later events send.
- GET `/push/devices` returns 404; that route could not verify persisted device
  registration. Earlier app logs show POST registration accepted, which is not
  proof of Firebase delivery.
- iOS source has background remote-notification mode but no Runner push
  entitlement or CODE_SIGN_ENTITLEMENTS setting. APNs-key setup in Firebase and
  signing capabilities still need verification outside the repository.

## Client changes

- Removed unsupported notification page parameter and synthetic inbox fallback.
  Empty lists now remain empty; endpoint failures reach the screen's error UI.
- Attach FCM listeners before permission/local-notification setup can fail.
- Wait for an Apple APNs token before requesting an FCM token; retry a bounded
  number of times and retry token synchronization on app resume.
- Leave background notification-payload display to the OS to avoid duplicates.
- Use millisecond timestamps rather than the 0–999 millisecond component for
  local notification IDs. Show foreground Apple notifications through the local
  notification path instead of requesting two banners.
- Add debug-only `[PUSH]` delivery-stage metadata without tokens, message bodies,
  or headers.

## Unverified backend and delivery stages

The actual backend implementation is absent. Check these with its developer:

1. Each chat, approval, and rejection event selects the intended recipient and
   creates a notification record where the product expects one.
2. `/push/devices` persists the phone's current FCM registration token against
   the correct authenticated user. Confirm the installationId field's contract.
3. Firebase Admin credentials target `vera-2a46c`; inspect the send response and
   structured error code for the specific event (without sharing credentials).
4. Confirm dispatch jobs execute and successful database writes do not hide
   failed Firebase sends. Confirm notification/data payload and priority.
5. Use a direct Firebase-console test to separate device transport from backend
   event dispatch. Test foreground and ordinary background separately. Android
   force-stop and Apple user-quit behavior require separate expectations.

## Validation

32 Flutter tests pass, including APNs readiness, Android token loading, endpoint
query compatibility, empty results, and error propagation. This does not replace
an end-to-end Firebase delivery test on a physical device.

References:
- https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
