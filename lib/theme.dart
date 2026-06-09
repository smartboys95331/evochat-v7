import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryDark = Color(0xFF5E35B1);
  static const Color accent = Color(0xFF00E5FF);
  static const Color bgDark = Color(0xFF0D0D1A);
  static const Color bgCard = Color(0xFF1A1A2E);
  static const Color bgCard2 = Color(0xFF16213E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color myBubble = Color(0xFF7C4DFF);
  static const Color theirBubble = Color(0xFF1E1E3A);
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF757575);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: bgCard,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
        ),
      );
}
