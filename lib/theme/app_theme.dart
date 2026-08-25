import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';



class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColor.primary, primary: AppColor.primary, surface: AppColor.surface, background: AppColor.background),
      scaffoldBackgroundColor: AppColor.background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
        bodyLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColor.textPrimary),
        bodyMedium: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: AppColor.textSecondary),
        bodySmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: AppColor.textLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
        iconTheme: const IconThemeData(color: AppColor.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: AppColor.bottomNavBg, selectedItemColor: AppColor.primary, unselectedItemColor: AppColor.textLight, type: BottomNavigationBarType.fixed, elevation: 12),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(color: AppColor.textLight, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColor.cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: AppColor.divider, thickness: 1),
    );
  }
}
