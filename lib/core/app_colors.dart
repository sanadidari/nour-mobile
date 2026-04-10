import 'package:flutter/material.dart';

class AppColors {
  final bool isLight;
  const AppColors({required this.isLight});

  Color get primaryNavy =>
      isLight ? const Color(0xFF0A1628) : const Color(0xFF0A1628);
  Color get primaryNavyLight =>
      isLight ? const Color(0xFF162240) : const Color(0xFF162240);
  Color get accentGold => const Color(0xFFD4A537);
  Color get accentGoldLight => const Color(0xFFF0D78C);

  Color get bgDark =>
      isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0E1A2E);
  Color get bgCard =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF142035);
  Color get bgSurface =>
      isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1A2942);
  Color get bgInput =>
      isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2F4A);

  Color get textPrimary =>
      isLight ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get textSecondary =>
      isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
  Color get textMuted =>
      isLight ? const Color(0xFF64748B) : const Color(0xFF64748B);

  Color get success => const Color(0xFF10B981);
  Color get error => const Color(0xFFEF4444);
  Color get warning => const Color(0xFFF59E0B);
  Color get info => const Color(0xFF3B82F6);

  Color get border =>
      isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E3A5F);
  Color get borderLight =>
      isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2A4A6B);
}

extension AppThemeContext on BuildContext {
  AppColors get appColors =>
      AppColors(isLight: Theme.of(this).brightness == Brightness.light);
}
