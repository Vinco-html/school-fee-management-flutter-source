import 'package:flutter/material.dart';

class AppTheme {
  static const ink = Color(0xFF1E2936);
  static const muted = Color(0xFF748093);
  static const peach = Color(0xFFFF9162);
  static const green = Color(0xFF2D866F);
  static const blue = Color(0xFF5275D9);
  static const canvas = Color(0xFFF5F7F6);
  static const card = Color(0xFFB00020);
  static const line = Color(0xFFE6EBE9);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: peach,
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: ink,
        ),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: peach, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        //   cardTheme: CardTheme(
        //     color: Colors.white,
        //     elevation: 0,
        //     margin: EdgeInsets.zero,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(22),
        //       side: const BorderSide(color: line),
        //     ),
        //   ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: ink),
          bodyMedium: TextStyle(color: muted),
        ),
      );
}
