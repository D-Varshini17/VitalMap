import 'package:flutter/material.dart';

class AppStyles {
  static const Color primary = Color(0xFF078C9E);
  static const Color accent = Color(0xFF18B7C9);
  static const Color page = Color(0xFFF6FBFD);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF16313A);
  static const Color muted = Color(0xFF667A83);
  static const Color border = Color(0xFFD9EEF3);

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: page,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: page,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: muted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: text),
      bodyMedium: TextStyle(color: muted),
      labelLarge: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
