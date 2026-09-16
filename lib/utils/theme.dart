import 'package:flutter/material.dart';

class AppColors {
  // 1. BRAND & CATEGORY COLORS (Remain static const as they don't change)
  static const primary = Color(0xFF2EA043);
  static const primaryLight = Color(0xFF3FB950);
  static const expense = Color(0xFFE05252);
  static const expenseLight = Color(0xFFFF6B6B);
  static const warning = Color(0xFFF0883E);
  static const info = Color(0xFF58A6FF);
  static const purple = Color(0xFF8B5CF6);
  static const teal = Color(0xFF06B6D4);

  static const catFood = Color(0xFFFF6B6B);
  static const catTravel = Color(0xFF4ECDC4);
  static const catShopping = Color(0xFFFFE66D);
  static const catBills = Color(0xFF58A6FF);
  static const catHealth = Color(0xFF2EA043);
  static const catEntertainment = Color(0xFF8B5CF6);
  static const catEducation = Color(0xFFF0883E);
  static const catOther = Color(0xFF8B949E);

  // 2. THEME-DEPENDENT COLORS (Dynamic via BuildContext)
  static bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) => _isDark(context) ? const Color(0xFF0D1117) : const Color(0xFFF5F7FA);
  static Color surface(BuildContext context) => _isDark(context) ? const Color(0xFF161B22) : Colors.white;
  static Color card(BuildContext context) => _isDark(context) ? const Color(0xFF1C2333) : Colors.white;
  static Color cardAlt(BuildContext context) => _isDark(context) ? const Color(0xFF21262D) : const Color(0xFFF8FAFC);
  static Color textPrimary(BuildContext context) => _isDark(context) ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E);
  static Color textSecondary(BuildContext context) => _isDark(context) ? const Color(0xFF8B949E) : const Color(0xFF64748B);
  static Color textMuted(BuildContext context) => _isDark(context) ? const Color(0xFF484F58) : const Color(0xFF94A3B8);
  static Color border(BuildContext context) => _isDark(context) ? const Color(0xFF30363D) : const Color(0xFFE2E8F0);
  static Color borderLight(BuildContext context) => _isDark(context) ? const Color(0xFF21262D) : const Color(0xFFF1F5F9);
  static Color inputFill(BuildContext context) => _isDark(context) ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117), // Fixed
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: Color(0xFF161B22), // Fixed
          error: AppColors.expense,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22), // Fixed
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFE6EDF3), // Fixed
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          iconTheme: IconThemeData(color: Color(0xFFE6EDF3)), // Fixed
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C2333), // Fixed
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF30363D), width: 1), // Fixed
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1117), // Fixed
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF30363D)), // Fixed
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF30363D)), // Fixed
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.expense),
          ),
          hintStyle: const TextStyle(color: Color(0xFF484F58), fontSize: 14), // Fixed
          labelStyle: const TextStyle(color: Color(0xFF8B949E)), // Fixed
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF30363D), // Fixed
          thickness: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161B22), // Fixed
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Color(0xFF8B949E), // Fixed
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFFE6EDF3), fontSize: 32, fontWeight: FontWeight.w800), // Fixed
          headlineMedium: TextStyle(color: Color(0xFFE6EDF3), fontSize: 24, fontWeight: FontWeight.w700), // Fixed
          titleLarge: TextStyle(color: Color(0xFFE6EDF3), fontSize: 18, fontWeight: FontWeight.w600), // Fixed
          titleMedium: TextStyle(color: Color(0xFFE6EDF3), fontSize: 16, fontWeight: FontWeight.w500), // Fixed
          bodyLarge: TextStyle(color: Color(0xFFE6EDF3), fontSize: 16), // Fixed
          bodyMedium: TextStyle(color: Color(0xFF8B949E), fontSize: 14), // Fixed
          labelLarge: TextStyle(color: Color(0xFFE6EDF3), fontSize: 14, fontWeight: FontWeight.w600), // Fixed
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: Colors.white,
          error: AppColors.expense,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Color(0xFF1A1A2E), fontSize: 20, fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white, selectedItemColor: AppColors.primary, unselectedItemColor: Color(0xFF94A3B8), type: BottomNavigationBarType.fixed, elevation: 8,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF1A1A2E), fontSize: 32, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(color: Color(0xFF1A1A2E), fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFF1A1A2E), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      );
}