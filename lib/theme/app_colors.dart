import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E5A78);
  static const Color primaryLight = Color(0xFF4D8792);

  static const Color population = Color(0xFF4D8792);
  static const Color internet = Color(0xFF1E5A78);
  static const Color domains = Color(0xFF4D6FA3);
  static const Color general = Color(0xFF8A6D3B);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB8860B);
  static const Color danger = Color(0xFFD32F2F);

  static Color border = Colors.grey.withValues(alpha: 0.15);
  static Color cardShadow = Colors.black.withValues(alpha: 0.06);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color forCategory(String category) {
    switch (category) {
      case 'Population':
        return population;
      case 'Internet':
        return internet;
      case 'Domains':
        return domains;
      default:
        return general;
    }
  }
}

class AppSpacing {
  AppSpacing._();

  static const double screenPadding = 20;
  static const double sectionGap = 26;
  static const double cardRadius = 18;
  static const double heroRadius = 22;
}
