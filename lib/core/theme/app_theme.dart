import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6366F1), // Indigo
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0E7FF),
        onPrimaryContainer: Color(0xFF1E1B4B),
        secondary: Color(0xFF8B5CF6), // Purple
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF3E8FF),
        onSecondaryContainer: Color(0xFF2D1B69),
        tertiary: Color(0xFF06B6D4), // Cyan
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFE0F2FE),
        onTertiaryContainer: Color(0xFF0C4A6E),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF7F1D1D),
        background: Color(0xFFFAFAFA),
        onBackground: Color(0xFF1F2937),
        surface: Colors.white,
        onSurface: Color(0xFF1F2937),
        surfaceVariant: Color(0xFFF3F4F6),
        onSurfaceVariant: Color(0xFF6B7280),
        outline: Color(0xFFD1D5DB),
        outlineVariant: Color(0xFFE5E7EB),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF1F2937),
        onInverseSurface: Color(0xFFF9FAFB),
        inversePrimary: Color(0xFFA5B4FC),
        surfaceTint: Color(0xFF6366F1),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFF1F2937),
        displayColor: const Color(0xFF1F2937),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF9CA3AF),
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF6B7280),
          fontSize: 16,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF6366F1),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: const ColorScheme.dark(
        primary: AppPalette.primaryA,
        secondary: AppPalette.primaryB,
        tertiary: AppPalette.primaryB,
        background: AppPalette.background,
        surface: AppPalette.surface,
        surfaceVariant: Color(0xFF1B263A),
        error: AppPalette.error,
        onPrimary: AppPalette.textPrimary,
        onSecondary: AppPalette.background,
        onTertiary: AppPalette.background,
        onBackground: AppPalette.textPrimary,
        onSurface: AppPalette.textPrimary,
        onSurfaceVariant: AppPalette.textSecondary,
        outline: AppPalette.outline,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppPalette.textPrimary,
        displayColor: AppPalette.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppPalette.primaryA,
          foregroundColor: AppPalette.textPrimary,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.textPrimary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface2.withOpacity(0.85),
        prefixIconColor: AppPalette.textSecondary,
        suffixIconColor: AppPalette.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.primaryB, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppPalette.textSecondary,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          color: AppPalette.textSecondary,
          fontSize: 16,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: AppPalette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppPalette.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.primaryB,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.surface.withOpacity(0.95),
        contentTextStyle: GoogleFonts.poppins(color: AppPalette.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.poppins(
          color: AppPalette.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: AppPalette.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
