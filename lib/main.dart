import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/splash/presentation/pages/splash_screen.dart';
import 'core/theme/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VeraApp());
}

class VeraApp extends StatelessWidget {
  const VeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VERA',
      debugShowCheckedModeBanner: false,
      theme: VeraTheme.dark,
      home: const SplashScreen(),
    );
  }
}
