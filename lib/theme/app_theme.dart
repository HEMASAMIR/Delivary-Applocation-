import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Inter',

    // خلفية أوبر الداكنة الرسمية
    scaffoldBackgroundColor: AppColors.primary,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.secondary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.secondary),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // أزرار أوبر
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        elevation: 0,
      ),
    ),

    // تصميم حقول الإدخال
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF222222),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.secondary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Colors.grey),
    ),

    // نصوص أوبر
    textTheme: const TextTheme(
      displayLarge:
          TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: AppColors.secondary),
      bodyMedium: TextStyle(color: Colors.grey),
    ),

    dividerColor: const Color(0xFF222222),
  );
}
