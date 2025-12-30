import 'package:flutter/material.dart';
import 'package:mymanager/theme/app_colors.dart';

/// Centralized decorations, borders, and shapes for the entire app
class AppDecorations {
  // Border Radius
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(24));
  
  static const BorderRadius radiusTopLarge = BorderRadius.vertical(top: Radius.circular(24));
  
  // Paddings
  static const EdgeInsets paddingSmall = EdgeInsets.all(8);
  static const EdgeInsets paddingMedium = EdgeInsets.all(12);
  static const EdgeInsets paddingLarge = EdgeInsets.all(16);
  static const EdgeInsets paddingXLarge = EdgeInsets.all(24);
  
  // Glass Effect Decoration
  static BoxDecoration glassDecoration = BoxDecoration(
    color: AppColors.glassBackground,
    borderRadius: radiusMedium,
    border: Border.all(
      color: AppColors.glassBorder,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.glassShadow,
        blurRadius: 10,
        spreadRadius: 5,
      ),
    ],
  );
  
  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.glassBackground,
    borderRadius: radiusMedium,
    border: Border.all(
      color: AppColors.glassBorder,
      width: 1,
    ),
  );
  
  // Modal Sheet Decoration
  static BoxDecoration modalDecoration = BoxDecoration(
    gradient: AppColors.darkGradient,
    borderRadius: radiusTopLarge,
  );
  
  // Container with Gradient Background
  static BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
  );
  
  // Icon Container Decoration
  static BoxDecoration iconContainerDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.2),
    borderRadius: radiusMedium,
  );
  
  // Button Decoration
  static BoxDecoration buttonDecoration(Color color) => BoxDecoration(
    color: color,
    borderRadius: radiusMedium,
  );
  
  // Divider Handle (for bottom sheets)
  static BoxDecoration handleDecoration = BoxDecoration(
    color: AppColors.overlayMedium,
    borderRadius: const BorderRadius.all(Radius.circular(2)),
  );
  
  // Input Field Decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    suffixIcon: suffix,
    labelStyle: AppColors.textSecondary == Colors.white70 
      ? TextStyle(color: AppColors.textSecondary) 
      : null,
    border: OutlineInputBorder(
      borderRadius: radiusMedium,
      borderSide: BorderSide(color: AppColors.glassBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radiusMedium,
      borderSide: BorderSide(color: AppColors.glassBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radiusMedium,
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
  );
  
  // Shapes
  static const ShapeBorder circleShape = CircleBorder();
  
  static RoundedRectangleBorder roundedShape(double radius) => 
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
}
