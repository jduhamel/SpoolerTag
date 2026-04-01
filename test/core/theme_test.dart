import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spooler_tag/core/theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme primary color is DarkGoldenrod', () {
      expect(
        AppTheme.light.colorScheme.primary,
        const Color(0xFFB8860B),
      );
    });

    test('dark theme primary color is Gold', () {
      expect(
        AppTheme.dark.colorScheme.primary,
        const Color(0xFFFFD700),
      );
    });

    test('light theme uses Material 3', () {
      expect(AppTheme.light.useMaterial3, isTrue);
    });

    test('dark theme uses Material 3', () {
      expect(AppTheme.dark.useMaterial3, isTrue);
    });

    test('light theme has light brightness', () {
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
    });

    test('dark theme has dark brightness', () {
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });
  });
}
