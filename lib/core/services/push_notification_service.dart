import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'push_token_loader.dart';
import 'push_diagnostics.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../../features/home/data/datasources/moments_remote_data_source.dart';
import '../../features/home/data/repositories/moments_repository_impl.dart';
import '../../features/home/presentation/pages/locked_moment_screen.dart';
import '../../features/home/presentation/pages/notifications_screen.dart';
import '../../features/home/presentation/pages/unlocked_moment_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  logPushDiagnostic('received', {
    'state': 'background',
    'hasNotification': message.notification != null,
    'dataKeys': message.data.keys.toList(),
  });
  // Notification payloads are displayed by the OS in the background.
  if (message.notification != null) return;

  try {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title != null || body != null || message.data.isNotEmpty) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await flutterLocalNotificationsPlugin.initialize(initSettings);

      final momentId =
          message.data['momentId']?.toString() ??
          message.data['moment_id']?.toString() ??
          message.data['id']?.toString() ??
          message.data['moment']?.toString();

      const androidDetails = AndroidNotificationDetails(
        'vera_moments_channel',
        'VERA Moments',
        channelDescription:
            'Notifications for private moments, invitations, and approvals',
        importance: Importance.high,
        priority: Priority.high,
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

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title ?? message.data['title']?.toString() ?? 'VERA Notification',
        body ??
            message.data['body']?.toString() ??
            'You have a new notification',
        details,
        payload: momentId,
      );
    }
  } catch (e) {
    debugPrint('Error handling background push notification: $e');
  }
}

class PushNotificationService with WidgetsBindingObserver {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final ValueNotifier<int> unreadNotificationsCount = ValueNotifier<int>(0);
  final ValueNotifier<RemoteMessage?> latestForegroundMessage =
      ValueNotifier<RemoteMessage?>(null);

  bool _listenersInitialized = false;
  bool _initialMessageChecked = false;
  bool _observingLifecycle = false;
  Timer? _tokenRetry;
  int _tokenRetryAttempts = 0;

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
      _initializeListeners(messaging);
      if (!_observingLifecycle) {
        WidgetsBinding.instance.addObserver(this);
        _observingLifecycle = true;
      }
      logPushDiagnostic('initialize', {
        'platform': Platform.operatingSystem,
        'firebaseProject': Firebase.app().options.projectId,
        'authenticated': apiClient.isAuthenticated,
      });

      // Initialize local notifications plugin
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
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
          description:
              'Notifications for private moments, invitations, and approvals',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(androidChannel);
      }

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
      if (Platform.isIOS || Platform.isMacOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        );
      }

      final initialMessage = _initialMessageChecked
          ? null
          : await messaging.getInitialMessage();
      _initialMessageChecked = true;
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

      // Get FCM token
      await _loadToken(messaging);

      if (_fcmToken != null &&
          _fcmToken!.isNotEmpty &&
          apiClient.isAuthenticated) {
        await _registerWithBackend(apiClient, _fcmToken!);
      }

      // Refresh unread count
      await refreshUnreadCount(apiClient);
    } catch (e) {
      logPushDiagnostic('initialize_error', {
        'code': e is FirebaseException ? e.code : e.runtimeType.toString(),
      });
    }
  }

  void _initializeListeners(FirebaseMessaging messaging) {
    if (_listenersInitialized) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      final client = _apiClient;
      if (client != null && client.isAuthenticated) {
        _registerWithBackend(client, newToken);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logPushDiagnostic('received', {
        'state': 'foreground',
        'hasNotification': message.notification != null,
        'dataKeys': message.data.keys.toList(),
      });
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
      logPushDiagnostic('opened', {'dataKeys': message.data.keys.toList()});
      latestForegroundMessage.value = message;
      handleNotificationTap(message);
    });

    _listenersInitialized = true;
    logPushDiagnostic('listeners_ready', {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tokenRetryAttempts = 0;
      final client = _apiClient;
      if (client != null) unawaited(onTokensUpdated(client));
    }
  }

  Future<void> _loadToken(FirebaseMessaging messaging) async {
    _fcmToken = await loadPushToken(
      requiresApns: Platform.isIOS || Platform.isMacOS,
      getApnsToken: messaging.getAPNSToken,
      getFcmToken: messaging.getToken,
    );
    logPushDiagnostic('token_state', {
      'platform': Platform.operatingSystem,
      'hasFcmToken': _fcmToken != null && _fcmToken!.isNotEmpty,
    });
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      _tokenRetry?.cancel();
      _tokenRetry = null;
      _tokenRetryAttempts = 0;
    }
    if (_fcmToken == null && (Platform.isIOS || Platform.isMacOS)) {
      logPushDiagnostic('apns_pending', {'retryAttempt': _tokenRetryAttempts});
      if (_tokenRetry == null && _tokenRetryAttempts < 6) {
        _tokenRetryAttempts++;
        _tokenRetry = Timer(const Duration(seconds: 5), () {
          _tokenRetry = null;
          final client = _apiClient;
          if (client != null) unawaited(onTokensUpdated(client));
        });
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final title =
          notification?.title ??
          message.data['title']?.toString() ??
          'VERA Notification';
      final body =
          notification?.body ??
          message.data['body']?.toString() ??
          'You have a new notification';
      final momentId =
          message.data['momentId']?.toString() ??
          message.data['moment_id']?.toString() ??
          message.data['id']?.toString() ??
          message.data['moment']?.toString();

      const androidDetails = AndroidNotificationDetails(
        'vera_moments_channel',
        'VERA Moments',
        channelDescription:
            'Notifications for private moments, invitations, and approvals',
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
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title,
        body,
        details,
        payload: momentId,
      );
      logPushDiagnostic('local_display_requested', {'state': 'foreground'});
    } catch (e) {
      logPushDiagnostic('display_failed', {
        'errorType': e.runtimeType.toString(),
      });
    }
  }

  Future<void> onTokensUpdated(ApiClient apiClient) async {
    _apiClient = apiClient;
    try {
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        await _loadToken(FirebaseMessaging.instance);
      }
      if (!apiClient.isAuthenticated) return;
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _registerWithBackend(apiClient, _fcmToken!);
      }
      await refreshUnreadCount(apiClient);
    } catch (e) {
      logPushDiagnostic('token_sync_error', {
        'code': e is FirebaseException ? e.code : e.runtimeType.toString(),
      });
    }
  }

  Future<void> handlePayloadTap(String momentId) async {
    final client = _apiClient;
    if (momentId.isNotEmpty && client != null && client.isAuthenticated) {
      try {
        final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
        final momentModel = await MomentsRemoteDataSource(client).getInboxMomentById(momentId)
            .catchError((_) => null) ?? await repo.getMomentById(momentId);
        final moment = momentModel.toEntity();
        if (_navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => moment.canAccessContent
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
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  Future<void> handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final momentId =
        data['momentId']?.toString() ??
        data['moment_id']?.toString() ??
        data['id']?.toString() ??
        data['moment']?.toString();
    if (momentId != null && momentId.isNotEmpty) {
      await handlePayloadTap(momentId);
    } else {
      if (_navigatorKey?.currentState != null) {
        _navigatorKey!.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
        );
      }
    }
  }

  Future<void> _registerWithBackend(ApiClient apiClient, String token) async {
    try {
      if (!apiClient.isAuthenticated) return;
      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      final response = await apiClient.post(
        '/push/devices',
        body: {'installationId': token, 'platform': platform},
      );
      logPushDiagnostic('backend_registration_accepted', {
        'platform': platform,
        'deliveryConfirmed': false,
        'responseKeys': response is Map
            ? response.keys.map((key) => key.toString()).toList()
            : [],
      });
    } catch (e) {
      logPushDiagnostic('backend_registration_failed', {
        'errorType': e.runtimeType.toString(),
        if (e is ApiException) 'httpStatus': e.statusCode,
      });
    }
  }

  Future<void> unregisterDevice(ApiClient apiClient) async {
    try {
      if (_fcmToken != null && apiClient.isAuthenticated) {
        await apiClient.delete(
          '/push/devices',
          body: {'installationId': _fcmToken!},
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
