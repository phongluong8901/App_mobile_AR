import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo Modern
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color secondary = Color(
    0xFF06B6D4,
  ); // Cyan Cyberpunk (phù hợp AR)

  // Neutral Colors - Light Mode
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Neutral Colors - Dark Mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // AR Overlay UI Colors (Kính mờ - Glassmorphism)
  static Color arOverlayBackground = Colors.black.withValues(alpha: 0.4);
  static Color arControlBorder = Colors.white.withValues(alpha: 0.2);
}
