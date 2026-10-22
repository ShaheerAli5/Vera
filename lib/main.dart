import 'package:flutter/material.dart';

import 'features/splash/presentation/pages/splash_screen.dart';
import 'core/theme/theme.dart';

void main() => runApp(const VeraApp());

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
