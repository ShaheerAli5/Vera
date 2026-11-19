import 'package:flutter_test/flutter_test.dart';
import 'package:vera/core/services/push_token_loader.dart';

void main() {
  test('Apple defers FCM token lookup until APNs is available', () async {
    var fcmCalls = 0;
    String? apns;
    Future<String?> getFcmToken() async {
      fcmCalls++;
      return 'test-fcm';
    }

    expect(
      await loadPushToken(
        requiresApns: true,
        getApnsToken: () async => apns,
        getFcmToken: getFcmToken,
      ),
      isNull,
    );
    expect(fcmCalls, 0);
    apns = 'test-apns';
    expect(
      await loadPushToken(
        requiresApns: true,
        getApnsToken: () async => apns,
        getFcmToken: getFcmToken,
      ),
      'test-fcm',
    );
    expect(fcmCalls, 1);
  });

  test('Android obtains FCM token without requesting an APNs token', () async {
    expect(
      await loadPushToken(
        requiresApns: false,
        getApnsToken: () async => throw StateError('APNs is not supported'),
        getFcmToken: () async => 'android-token',
      ),
      'android-token',
    );
  });

  test('empty APNs token defers registration', () async {
    expect(
      await loadPushToken(
        requiresApns: true,
        getApnsToken: () async => '',
        getFcmToken: () async => throw StateError('FCM must not run yet'),
      ),
      isNull,
    );
  });

  test(
    'FCM failure propagates so callers report a failed sync, not success',
    () async {
      await expectLater(
        loadPushToken(
          requiresApns: false,
          getApnsToken: () async => null,
          getFcmToken: () async => throw StateError('FCM unavailable'),
        ),
        throwsStateError,
      );
    },
  );
}
