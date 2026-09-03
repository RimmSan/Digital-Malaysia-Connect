import 'package:flutter/material.dart';

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
