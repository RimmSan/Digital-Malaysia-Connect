import 'package:flutter/material.dart';

// ============================================================
// APP COLORS
// ------------------------------------------------------------
// Single source of truth for the app's palette, pulled out of
// the Dashboard module so every other module (Analytics, Growth,
// Intelligence, Settings) can reuse the exact same colors instead
// of re-picking hex values by eye. Import this instead of typing
// Color(0xFF...) directly.
// ============================================================

class AppColors {
  AppColors._();

  // Brand / primary gradient
  static const Color primary = Color(0xFF1E5A78);
  static const Color primaryLight = Color(0xFF4D8792);

  // Category accents (also used by DashboardNote categories)
  static const Color population = Color(0xFF4D8792);
  static const Color internet = Color(0xFF1E5A78);
  static const Color domains = Color(0xFF4D6FA3);
  static const Color general = Color(0xFF8A6D3B);

  // Status colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB8860B);
  static const Color danger = Color(0xFFD32F2F);

  // Neutral helpers (use Colors.grey.shadeXXX directly for most
  // text; these are for the handful of non-standard shades)
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

// ============================================================
// SHARED LAYOUT CONSTANTS
// ============================================================

class AppSpacing {
  AppSpacing._();

  static const double screenPadding = 20;
  static const double sectionGap = 26;
  static const double cardRadius = 18;
  static const double heroRadius = 22;
}
