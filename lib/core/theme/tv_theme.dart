import 'package:flutter/material.dart';

/// Leanback-style theme for Android TV.
class TvTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A73E8),
        brightness: Brightness.dark,
        // TV: larger text, no elevation on app bar
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24),
          bodyLarge: TextStyle(fontSize: 18),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          toolbarHeight: 80,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
}
