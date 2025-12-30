import 'package:flutter/material.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/theme/app_text_styles.dart';
import 'package:mymanager/theme/app_decorations.dart';

/// Main theme configuration
/// Uses centralized colors, text styles, and decorations
class AppTheme {
  // Quick access to common theme elements
  static LinearGradient get backgroundGradient => AppColors.primaryGradient;
  
  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: AppColors.transparent,
    textTheme: TextTheme(
      displayLarge: AppTextStyles.headline1,
      displayMedium: AppTextStyles.headline2,
      headlineMedium: AppTextStyles.headline3,
      headlineSmall: AppTextStyles.headline4,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.label,
      labelSmall: AppTextStyles.caption,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      titleTextStyle: AppTextStyles.headline2,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textPrimary,
      shape: AppDecorations.circleShape,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.textPrimary,
        textStyle: AppTextStyles.buttonMedium,
        shape: AppDecorations.roundedShape(12),
      ),
    ),
  );
}
