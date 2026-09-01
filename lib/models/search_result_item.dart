import 'package:flutter/material.dart';

// ============================================================
// SEARCH RESULT ITEM
// ------------------------------------------------------------
// A single row shown under the dashboard's global search bar.
// Category is a short label like "State", "Metric", "Dataset" or
// "My Insight" so results from different sources are visually
// distinguishable.
// ============================================================

class SearchResultItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SearchResultItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
