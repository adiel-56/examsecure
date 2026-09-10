import 'package:flutter/material.dart';

/// Palette reprise exactement de la maquette HTML fournie (variables CSS).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF3B5BDB);
  static const primaryDark = Color(0xFF2B44A6);
  static const primarySoft = Color(0xFFEDF0FE);
  static const accent = Color(0xFFF59F00);
  static const bg = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1B2430);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF8A97AD);
  static const border = Color(0xFFE3E8F0);
  static const success = Color(0xFF2F9E44);
  static const successSoft = Color(0xFFE7F6EC);
  static const danger = Color(0xFFE03131);
  static const dangerSoft = Color(0xFFFDECEC);
  static const warning = Color(0xFFE8590C);
  static const warningSoft = Color(0xFFFFF3E0);
  static const navy = Color(0xFF14213D);
  static const adminAccent = Color(0xFF4CC9F0);
}

class AppTheme {
  AppTheme._();

  static ThemeData get student => _base(AppColors.primary);
  static ThemeData get admin => _base(AppColors.navy, isAdmin: true);

  static ThemeData _base(Color seed, {bool isAdmin = false}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, primary: seed),
      scaffoldBackgroundColor: AppColors.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: isAdmin ? AppColors.navy : AppColors.bg,
        foregroundColor: isAdmin ? Colors.white : AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          side: BorderSide(color: seed, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seed, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: seed,
        unselectedItemColor: AppColors.faint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
