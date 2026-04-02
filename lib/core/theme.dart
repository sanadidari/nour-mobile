import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
export 'app_colors.dart';

class AppTheme {
  // Re-define constants for the theme builder
  static const darkColors = AppColors(isLight: false);
  static const lightColors = AppColors(isLight: true);

  static ThemeData get darkPremiumTheme {
    return _buildTheme(darkColors, Brightness.dark);
  }

  static ThemeData get lightTheme {
    return _buildTheme(lightColors, Brightness.light);
  }

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: GoogleFonts.cairo().fontFamily,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accentGold,
        onPrimary: colors.primaryNavy,
        secondary: colors.accentGold,
        onSecondary: colors.primaryNavy,
        error: colors.error,
        onError: Colors.white,
        surface: colors.bgCard,
        onSurface: colors.textPrimary,
      ),
      scaffoldBackgroundColor: colors.bgDark,
      textTheme: GoogleFonts.cairoTextTheme().copyWith(
        displayLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: colors.textPrimary),
        headlineMedium: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: colors.textPrimary),
        titleLarge: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: colors.textPrimary),
        bodyLarge: GoogleFonts.cairo(color: colors.textPrimary),
        bodyMedium: GoogleFonts.cairo(color: colors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgCard,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
        shape: Border(
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border, width: 0.5),
        ),
        color: colors.bgCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentGold,
          foregroundColor: colors.primaryNavy,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: colors.borderLight),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accentGold, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(color: colors.textMuted),
        hintStyle: GoogleFonts.cairo(color: colors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: colors.bgCard,
        textColor: colors.textPrimary,
        iconColor: colors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 0.5),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.bgSurface,
        contentTextStyle: GoogleFonts.cairo(color: colors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
        contentTextStyle: GoogleFonts.cairo(color: colors.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgCard,
        surfaceTintColor: colors.bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accentGold,
        foregroundColor: colors.primaryNavy,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accentGold,
      ),
    );
  }
}
