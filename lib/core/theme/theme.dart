import 'package:flutter/material.dart';

/// Centralized VERA color palette and Material theme.
abstract final class VeraTheme {
  // Brand Purples & Gradients
  static const Color purple = Color(0xFF9044FB);
  static const Color purpleBright = Color(0xFFC057FF);
  static const Color purpleAccent = Color(0xFFB02BFF);
  static const Color violet = Color(0xFF7A35E8);
  static const Color glowPurple = Color(0x77A03BFF);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFF080914);
  static const Color scaffoldBackground = Color(0xFF090A17);
  static const Color surface = Color(0xFF121326);
  static const Color surfaceRaised = Color(0xFF1A1B32);
  static const Color surfaceMuted = Color(0xFF24253D);
  static const Color inputBackground = Color(0xFF141527);
  static const Color chipBackground = Color(0xFF1B1C33);

  // Content & Typography
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFF7F5FF);
  static const Color textSecondary = Color(0xFFA6A6C1);
  static const Color textMuted = Color(0xFF6E6E8F);
  static const Color textSubtle = Color(0xFF535370);
  static const Color outline = Color(0xFF373850);

  // Status & Feedback
  static const Color success = Color(0xFF4ADE80);
  static const Color successGlass = Color(0x3322C55E);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF647C);
  static const Color info = Color(0xFF67B7FF);

  // Common Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, purpleBright],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF9451FF),
      Color(0xFF557AFB),
      Color(0xFF58C3F4),
    ],
  );

  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xDFC057FF),
      Color(0xBF8032C8),
      Color(0xDF4A1980),
    ],
  );

  static const LinearGradient navBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xD91B152E),
      Color(0xF2120D22),
    ],
  );

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: purple,
    onPrimary: Colors.white,
    primaryContainer: violet,
    onPrimaryContainer: Colors.white,
    secondary: purpleBright,
    onSecondary: Color(0xFF21003A),
    secondaryContainer: Color(0xFF40205C),
    onSecondaryContainer: Color(0xFFF3DFFF),
    tertiary: info,
    onTertiary: Color(0xFF00223D),
    tertiaryContainer: Color(0xFF123A5A),
    onTertiaryContainer: Color(0xFFD3E9FF),
    error: error,
    onError: Color(0xFF41000D),
    errorContainer: Color(0xFF69001A),
    onErrorContainer: Color(0xFFFFD9DE),
    surface: surface,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    outline: outline,
    outlineVariant: Color(0xFF292A40),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: textPrimary,
    onInverseSurface: background,
    inversePrimary: violet,
    surfaceTint: purple,
  );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Arial',
        colorScheme: colorScheme,
        scaffoldBackgroundColor: background,
        canvasColor: background,
        cardColor: surface,
        dividerColor: outline,
        disabledColor: textSecondary.withAlpha(115),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: surfaceRaised,
          contentTextStyle: TextStyle(color: textPrimary),
          actionTextColor: purpleBright,
          behavior: SnackBarBehavior.floating,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: textPrimary,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputBackground,
          hintStyle: const TextStyle(color: textSubtle),
          labelStyle: const TextStyle(color: textSecondary),
          floatingLabelStyle: const TextStyle(color: purpleBright),
          prefixIconColor: textSecondary,
          suffixIconColor: textSecondary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: purple, width: 1.5),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: purpleBright),
        ),
      );
}
