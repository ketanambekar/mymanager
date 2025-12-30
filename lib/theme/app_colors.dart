import 'package:flutter/material.dart';

/// Centralized color palette for the entire app
class AppColors {
  // Primary Colors
  static const Color primary = Colors.indigo;
  static const Color primaryLight = Color(0xFF5E6AD2);
  static final Color primaryDark = Colors.indigo.shade900;
  
  static const Color secondary = Colors.purple;
  static final Color secondaryDark = Colors.purple.shade900;
  
  static const Color accent = Colors.greenAccent;
  
  // Background Colors
  static final Color backgroundDark = Colors.deepPurple.shade900;
  static final Color backgroundLight = Colors.indigo.shade900;
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // white70
  static const Color textTertiary = Color(0x99FFFFFF); // white60
  static const Color textDisabled = Color(0x61FFFFFF); // white38
  
  // Status Colors
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;
  
  // Priority Colors (Eisenhower Matrix)
  static const Color urgentImportant = Color(0xFFFF5252); // Red
  static const Color urgentNotImportant = Color(0xFFFF9800); // Orange
  static const Color notUrgentImportant = Color(0xFF4CAF50); // Green
  static const Color notUrgentNotImportant = Color(0xFF2196F3); // Blue
  
  // Energy Level Colors
  static const Color highEnergy = Color(0xFFFF5722);
  static const Color mediumEnergy = Color(0xFFFFC107);
  static const Color lowEnergy = Color(0xFF4CAF50);
  
  // Glass Effect Colors
  static Color glassBackground = Colors.white.withOpacity(0.15);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  static Color glassShadow = Colors.black.withOpacity(0.1);
  
  // Overlay Colors
  static Color overlayLight = Colors.white.withOpacity(0.1);
  static Color overlayMedium = Colors.white.withOpacity(0.3);
  static Color overlayDark = Colors.black.withOpacity(0.22);
  
  // Card Colors
  static Color cardBackground = Colors.grey.shade900;
  
  // Transparent
  static const Color transparent = Colors.transparent;
  
  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [Colors.indigo.shade700, Colors.purple.shade700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get darkGradient => LinearGradient(
    colors: [Colors.deepPurple.shade900, Colors.indigo.shade900],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient modalGradient(double opacity) => LinearGradient(
    colors: [
      Colors.deepPurple.shade900.withOpacity(opacity),
      Colors.indigo.shade900.withOpacity(opacity),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
