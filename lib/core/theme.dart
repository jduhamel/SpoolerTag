import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Gold / Goldenrod palette
  static const _darkGold = Color(0xFFB8860B); // DarkGoldenrod
  static const _gold = Color(0xFFFFD700); // Gold

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkGold,
      brightness: Brightness.light,
      primary: _darkGold,
      primaryContainer: _gold,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _gold,
      brightness: Brightness.dark,
      primary: _gold,
      primaryContainer: _darkGold,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}
