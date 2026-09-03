import 'package:flutter/material.dart';
import '../models/search_result_item.dart';
import '../theme/app_colors.dart';


class DashboardSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final List<SearchResultItem> results;
  final bool isActive;

  const DashboardSearchBar({
    super.key,
    required this.controller,
    required this.results,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search states, metrics, datasets...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: controller.clear,
              )
                  : null,
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: results.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No matches. Try a state name, metric, or dataset.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: results.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.withValues(alpha: 0.12),
              ),
              itemBuilder: (context, index) {
                final r = results[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: r.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(r.icon, size: 16, color: r.color),
                  ),
                  title: Text(
                    r.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    r.subtitle,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  trailing: Text(
                    r.category,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  onTap: r.onTap,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
