import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background FCM message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final ValueNotifier<int> unreadNotificationsCount = ValueNotifier<int>(0);
  final ValueNotifier<RemoteMessage?> latestForegroundMessage = ValueNotifier<RemoteMessage?>(null);

  bool _initialized = false;

  Future<void> initialize(ApiClient apiClient) async {
    if (_initialized) return;
    _initialized = true;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request permissions (especially required on iOS & Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('User notification permission status: ${settings.authorizationStatus}');

      // Get FCM token
      _fcmToken = await messaging.getToken();
      debugPrint('FCM Device Token: $_fcmToken');

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _registerWithBackend(apiClient, _fcmToken!);
      }

      // Listen for token updates
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _registerWithBackend(apiClient, newToken);
      });

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground notification: ${message.notification?.title}');
        latestForegroundMessage.value = message;
        unreadNotificationsCount.value += 1;
      });

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Opened app from notification: ${message.data}');
      });

      // Refresh unread count
      await refreshUnreadCount(apiClient);
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
    }
  }

  Future<void> _registerWithBackend(ApiClient apiClient, String token) async {
    try {
      if (!apiClient.isAuthenticated) return;
      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      await apiClient.post(
        '/push/devices',
        body: {
          'installationId': token,
          'platform': platform,
        },
      );
      debugPrint('Push device registered successfully with VERA backend');
    } catch (e) {
      debugPrint('Failed to register push device with backend: $e');
    }
  }

  Future<void> unregisterDevice(ApiClient apiClient) async {
    try {
      if (_fcmToken != null && apiClient.isAuthenticated) {
        await apiClient.delete(
          '/push/devices',
          body: {
            'installationId': _fcmToken!,
          },
        );
        debugPrint('Push device unregistered from VERA backend');
      }
    } catch (e) {
      debugPrint('Failed to unregister push device: $e');
    }
  }

  Future<void> refreshUnreadCount(ApiClient apiClient) async {
    try {
      if (!apiClient.isAuthenticated) return;
      final response = await apiClient.get('/notifications/unread-count');
      if (response is Map<String, dynamic>) {
        final count = (response['unreadCount'] as num?)?.toInt() ?? 0;
        unreadNotificationsCount.value = count;
      }
    } catch (_) {}
  }
}
