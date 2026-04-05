import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color primaryDark = Color(0xFF002171);

  // Accent
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF62EFFF);
  static const Color accentDark = Color(0xFF008BA3);

  // Status Colors
  static const Color statusNormal = Color(0xFF43A047);
  static const Color statusWarning = Color(0xFFFFA000);
  static const Color statusCritical = Color(0xFFE53935);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF0D47A1),
    Color(0xFF00BCD4),
    Color(0xFF43A047),
    Color(0xFFFFA000),
    Color(0xFF9C27B0),
    Color(0xFFE53935),
  ];

  // Background
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF0A0E21);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1D2037);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E21), Color(0xFF1D2037)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
}
