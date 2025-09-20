import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Colors.indigo;
  static const Color secondaryColor = Colors.purple;
  static const Color accentColor = Colors.greenAccent;

  static TextStyle get headline => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get body => GoogleFonts.raleway(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  static TextStyle get bodySmall => GoogleFonts.raleway(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  static TextStyle get caption => GoogleFonts.raleway(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white60,
  );

  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: TextTheme(
      displayLarge: headline,
      displayMedium: headlineSmall,
      bodyLarge: body,
      bodyMedium: bodySmall,
      bodySmall: caption,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: headlineSmall,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
  );
}
