import 'package:flutter/material.dart';
import '../models/dashboard_note.dart';

class NoteCard extends StatelessWidget {
  final DashboardNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _categoryIcon {
    switch (note.category) {
      case 'Population':
        return Icons.people_alt_outlined;
      case 'Internet':
        return Icons.wifi;
      case 'Domains':
        return Icons.language;
      default:
        return Icons.push_pin_outlined;
    }
  }

  Color get _categoryColor {
    switch (note.category) {
      case 'Population':
        return const Color(0xFF4D8792);
      case 'Internet':
        return const Color(0xFF1E5A78);
      case 'Domains':
        return const Color(0xFF4D6FA3);
      default:
        return const Color(0xFF8A6D3B);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon, color: _categoryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${note.category} · ${_timeAgo(note.updatedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (note.highlightValue != null &&
                  note.highlightValue!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    note.highlightValue!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _categoryColor,
                    ),
                  ),
                ),
              // ---- Edit / Delete: explicit buttons, matching the
              // team's pattern (e.g. GrowthBookmarkCard) instead of
              // swipe-to-dismiss. Confirmation is handled by the
              // caller (DashboardPage._deleteNote), same as
              // GrowthPage._deleteBookmark.
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red.shade400,
                onPressed: onDelete,
              ),
            ],
          ),
          if (note.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.note,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
