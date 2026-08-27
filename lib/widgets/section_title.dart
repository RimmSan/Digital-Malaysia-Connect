import 'package:flutter/material.dart';

// ============================================================
// SECTION TITLE
// ------------------------------------------------------------
// Every module (Dashboard, Analytics, Growth, Intelligence) has
// section headings like "Key Digital Indicators". Use this widget
// everywhere instead of a raw Text(...) so font size/weight stay
// consistent, and so an optional trailing action (e.g. "See all",
// "Add", a filter button) is laid out the same way everywhere.
// ============================================================

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}
