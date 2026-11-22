import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static const orange = AppColors.orange;
  static const ink = AppColors.ink;
  static const canvas = AppColors.paper;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: orange,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.loginBackground,
      textTheme: TextTheme(
        bodySmall: TextStyle(fontSize: AppTypography.caption),
        bodyMedium: TextStyle(fontSize: AppTypography.body),
        titleMedium: TextStyle(fontSize: AppTypography.title),
        titleLarge: TextStyle(fontSize: AppTypography.pageTitle),
        displaySmall: TextStyle(fontSize: AppTypography.display),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E4E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E4E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.width(16),
          vertical: AppSpacing.height(15),
        ),
      ),
    );
  }
}
