import 'package:flutter/material.dart';

import 'neon_colors.dart';

final ThemeData neonThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: NeonColors.background,
  colorScheme: const ColorScheme.dark(
    surface: NeonColors.surface,
    primary: NeonColors.cyan,
    onPrimary: NeonColors.background,
    secondary: NeonColors.purple,
    onSecondary: NeonColors.textPrimary,
    tertiary: NeonColors.orange,
    onTertiary: NeonColors.background,
    error: NeonColors.red,
    onError: NeonColors.textPrimary,
    onSurface: NeonColors.textPrimary,
    surfaceContainerHighest: NeonColors.surface,
    onSurfaceVariant: NeonColors.textSecondary,
  ),
  textTheme:
      const TextTheme(
        bodyMedium: TextStyle(color: NeonColors.textPrimary),
        bodySmall: TextStyle(color: NeonColors.textSecondary),
      ).apply(
        bodyColor: NeonColors.textPrimary,
        displayColor: NeonColors.textPrimary,
      ),
);
