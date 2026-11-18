import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/theme.dart';
import 'features/splash/presentation/pages/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const configuredApiUrl = String.fromEnvironment('API_BASE_URL');
  final apiClient = ApiClient(
    config: AppConfig(
      apiBaseUrl: configuredApiUrl.isEmpty
          ? 'https://vera.aptechmedia.com'
          : configuredApiUrl,
    ),
  );
  await apiClient.initFromStorage();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PushNotificationService.instance.initialize(apiClient);
  runApp(VeraApp(apiClient: apiClient));
}

class VeraApp extends StatelessWidget {
  const VeraApp({required this.apiClient, super.key});

  final ApiClient apiClient;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    PushNotificationService.instance.setNavigatorKey(navigatorKey);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'VERA',
      debugShowCheckedModeBanner: false,
      theme: VeraTheme.dark,
      builder: (context, child) => ApiClientScope(
        client: apiClient,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}

class ApiClientScope extends InheritedWidget {
  const ApiClientScope({required this.client, required super.child, super.key});

  final ApiClient client;

  static ApiClient of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ApiClientScope>();
    assert(scope != null, 'ApiClientScope is missing above this context.');
    return scope!.client;
  }

  @override
  bool updateShouldNotify(ApiClientScope oldWidget) => client != oldWidget.client;
}
