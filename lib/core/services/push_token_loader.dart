/// Apple must provide its APNs token before Firebase can issue an FCM token.
/// Null means token registration should be retried later, not that login failed.
Future<String?> loadPushToken({
  required bool requiresApns,
  required Future<String?> Function() getApnsToken,
  required Future<String?> Function() getFcmToken,
}) async {
  if (requiresApns) {
    final apns = await getApnsToken();
    if (apns == null || apns.isEmpty) return null;
  }
  return getFcmToken();
}
