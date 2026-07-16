import 'package:flutter/material.dart';

/// Light theme for mobile devices.
class MobileTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A73E8),
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
