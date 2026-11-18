import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../network/api_client.dart';
import '../../features/home/data/datasources/moments_remote_data_source.dart';
import '../../features/home/data/repositories/moments_repository_impl.dart';
import '../../features/home/presentation/pages/locked_moment_screen.dart';
import '../../features/home/presentation/pages/notifications_screen.dart';
import '../../features/home/presentation/pages/unlocked_moment_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling background FCM message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final ValueNotifier<int> unreadNotificationsCount = ValueNotifier<int>(0);
  final ValueNotifier<RemoteMessage?> latestForegroundMessage = ValueNotifier<RemoteMessage?>(null);

  bool _listenersInitialized = false;
  ApiClient? _apiClient;
  GlobalKey<NavigatorState>? _navigatorKey;
  RemoteMessage? _pendingInitialMessage;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    if (_pendingInitialMessage != null) {
      final msg = _pendingInitialMessage!;
      _pendingInitialMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationTap(msg);
      });
    }
  }

  Future<void> initialize(ApiClient apiClient) async {
    _apiClient = apiClient;

    try {
      final messaging = FirebaseMessaging.instance;

      // Initialize local notifications plugin
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            handlePayloadTap(payload);
          } else {
            if (_navigatorKey?.currentState != null) {
              _navigatorKey!.currentState!.push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            }
          }
        },
      );

      // Create Android High Importance Notification Channel
      if (Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          'vera_moments_channel',
          'VERA Moments',
          description: 'Notifications for private moments, invitations, and approvals',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
      }

      if (!_listenersInitialized) {
        _listenersInitialized = true;
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        // Request permissions (Alert, Badge, Sound, POST_NOTIFICATIONS on Android 13+)
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint(
          'User notification permission status: ${settings.authorizationStatus}',
        );

        // Configure iOS foreground presentation options
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          final client = _apiClient;
          if (client != null && client.isAuthenticated) {
            _registerWithBackend(client, newToken);
          }
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            'Received foreground notification: ${message.notification?.title}',
          );
          latestForegroundMessage.value = message;
          unreadNotificationsCount.value += 1;

          // Show local system notification banner/drawer entry in foreground
          _showLocalNotification(message);

          final client = _apiClient;
          if (client != null && client.isAuthenticated) {
            refreshUnreadCount(client);
          }
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Opened app from notification: ${message.data}');
          latestForegroundMessage.value = message;
          handleNotificationTap(message);
        });

        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          latestForegroundMessage.value = initialMessage;
          if (_navigatorKey?.currentState != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              handleNotificationTap(initialMessage);
            });
          } else {
            _pendingInitialMessage = initialMessage;
          }
        }
      }

      // Get FCM token
      _fcmToken = await messaging.getToken();

      if (_fcmToken != null && _fcmToken!.isNotEmpty && apiClient.isAuthenticated) {
        await _registerWithBackend(apiClient, _fcmToken!);
      }

      // Refresh unread count
      await refreshUnreadCount(apiClient);
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString() ?? 'VERA Notification';
      final body = notification?.body ?? message.data['body']?.toString() ?? 'You have a new notification';
      final momentId = message.data['momentId']?.toString();

      const androidDetails = AndroidNotificationDetails(
        'vera_moments_channel',
        'VERA Moments',
        channelDescription: 'Notifications for private moments, invitations, and approvals',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: momentId,
      );
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  Future<void> onTokensUpdated(ApiClient apiClient) async {
    _apiClient = apiClient;
    try {
      if (!apiClient.isAuthenticated) return;
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        _fcmToken = await FirebaseMessaging.instance.getToken();
      }
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _registerWithBackend(apiClient, _fcmToken!);
      }
      await refreshUnreadCount(apiClient);
    } catch (e) {
      debugPrint('Error in onTokensUpdated: $e');
    }
  }

  Future<void> handlePayloadTap(String momentId) async {
    final client = _apiClient;
    if (momentId.isNotEmpty && client != null && client.isAuthenticated) {
      try {
        final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
        final momentModel = await repo.getMomentById(momentId);
        final moment = momentModel.toEntity();
        if (_navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => moment.isReadyToOpen
                  ? UnlockedMomentScreen(moment: moment)
                  : LockedMomentScreen(moment: moment),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Failed to open moment details from payload: $e');
      }
    }

    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationsScreen(),
        ),
      );
    }
  }

  Future<void> handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final momentId = data['momentId'] as String?;
    if (momentId != null && momentId.isNotEmpty) {
      await handlePayloadTap(momentId);
    } else {
      if (_navigatorKey?.currentState != null) {
        _navigatorKey!.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationsScreen(),
          ),
        );
      }
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
        final count =
            (response['unreadCount'] as num?)?.toInt() ??
            (response['count'] as num?)?.toInt() ??
            0;
        unreadNotificationsCount.value = count;
      }
    } catch (_) {}
  }
}
