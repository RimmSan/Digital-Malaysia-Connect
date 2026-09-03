import 'package:flutter/material.dart';
import '../models/growth_bookmark.dart';
import '../theme/app_colors.dart';

class GrowthBookmarkCard extends StatelessWidget {
  final GrowthBookmark bookmark;
  final int currentTotal;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GrowthBookmarkCard({
    super.key,
    required this.bookmark,
    required this.currentTotal,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  static String _formatCount(num value) {
    final isNegative = value < 0;
    final abs = value.abs();

    String formatted;
    if (abs >= 1000000) {
      formatted = '${(abs / 1000000).toStringAsFixed(2)}M';
    } else if (abs >= 1000) {
      formatted = '${(abs / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = abs.toStringAsFixed(0);
    }

    return isNegative ? '-$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.bookmark, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bookmark.label,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${_formatCount(bookmark.snapshotValue)} · '
                              '${bookmark.savedAt.day}/${bookmark.savedAt.month}/${bookmark.savedAt.year}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
            if (isSelected) _buildComparison(),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison() {
    final diff = currentTotal - bookmark.snapshotValue;
    final percent =
    bookmark.snapshotValue == 0 ? 0.0 : (diff / bookmark.snapshotValue) * 100;
    final isPositive = diff >= 0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isPositive ? AppColors.success : AppColors.danger).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Comparing to "${bookmark.label}"',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${isPositive ? '+' : ''}${_formatCount(diff)} '
                '(${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}%) since '
                '${bookmark.savedAt.day}/${bookmark.savedAt.month}/${bookmark.savedAt.year}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}