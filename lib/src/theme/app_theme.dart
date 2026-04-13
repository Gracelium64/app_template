import 'package:test_app/src/theme/palette.dart';
import 'package:flutter/material.dart';

abstract class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF111111),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      toolbarHeight: 60,
      titleTextStyle: TextStyle(
        color: Color(0xFF111111),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Color(0xFF111111)),
      centerTitle: false,
      // bottom border
      shape: Border(bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF555555)),
      bodyMedium: TextStyle(color: Color(0xFF555555), fontSize: 14),
      titleMedium: TextStyle(
        color: Color(0xFF111111),
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF111111),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dividerColor: const Color(0xFFE8E8E8),
  );
  static final darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.lightTeal,
      brightness: Brightness.dark,
    ),
    textTheme: baseTextTheme,

    progressIndicatorTheme: ProgressIndicatorThemeData(
      circularTrackColor: Palette.monarchPurple1,
      color: Palette.monarchPurple2,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.darkTeal,
      actionTextColor: Palette.basicBitchWhite,
      contentTextStyle: TextStyle(color: Palette.basicBitchWhite),
    ),
  );

  static final TextTheme baseTextTheme = TextTheme(
    bodyLarge: TextStyle(color: Palette.basicBitchBlack),
    bodyMedium: TextStyle(
      color: Palette.basicBitchWhite,
      fontFamily: 'Inter',
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: Palette.basicBitchWhite,
      fontFamily: 'Marvel',
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    // displayLarge: TextStyle(),
    displayMedium: TextStyle(
      color: Palette.basicBitchWhite,
      fontFamily: 'Marvel',
      fontSize: 24,
      fontWeight: FontWeight.w400,
    ),
    // displaySmall: TextStyle(),
    headlineLarge: TextStyle(
      fontFamily: 'Lobster',
      fontSize: 30,
      color: Palette.basicBitchWhite,
    ),
    headlineMedium: TextStyle(
      color: Palette.basicBitchWhite,
      fontFamily: 'Marvel',
      fontSize: 34,
      fontWeight: FontWeight.w400,
    ),
    // headlineSmall: TextStyle(),
    // labelLarge: TextStyle(),
    // labelMedium: TextStyle(),
    labelSmall: TextStyle(
      color: Palette.basicBitchWhite,
      fontFamily: 'Inter',
      fontSize: 8,
    ),
    titleLarge: TextStyle(
      color: Palette.basicBitchWhite,
      fontFamily: 'Marvel',
      fontSize: 40,
      fontWeight: FontWeight.w400,
    ),
    // titleMedium: TextStyle(),
    titleSmall: TextStyle(
      color: Palette.basicBitchWhite,
      fontFamily: 'Inter',
      fontSize: 10,
    ),
  );
}
