import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accentVibrant,
        surface: AppColors.bgElevated,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgElevated,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.accentDark,
      scaffoldBackgroundColor: AppColors.bgPrimaryDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentDark,
        secondary: AppColors.accentVibrantDark,
        surface: AppColors.bgElevatedDark,
        error: AppColors.errorDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimaryDark,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: TextStyle(color: AppColors.textPrimaryDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgElevatedDark,
        selectedItemColor: AppColors.accentDark,
        unselectedItemColor: AppColors.textSecondaryDark,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
        bodyMedium: TextStyle(color: AppColors.textSecondaryDark),
      ),
    );
  }
}
