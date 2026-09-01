import 'package:flutter/material.dart';
import '../models/state_population_data.dart';
import '../theme/app_colors.dart';
import '../utils/dashboard_stats.dart';

// ============================================================
// STATE RANKING SHEET
// ------------------------------------------------------------
// Previously, tapping the "Digital Highlights" card did nothing -
// the arrow was purely decorative. This sheet is the fix: it
// shows every state ranked by population, with an optional
// highlight for a state the user searched for.
// ============================================================

void showStateRankingSheet(
    BuildContext context, {
      required List<StatePopulationData> states,
      String? highlightState,
    }) {
  final sorted = [...states]
    ..sort((a, b) => b.population.compareTo(a.population));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text(
                  'State Population Ranking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sorted.length} states, ranked by population',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: sorted.isEmpty
                      ? Center(
                    child: Text(
                      'No state data available.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                      : ListView.builder(
                    controller: scrollController,
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final s = sorted[index];
                      final rank = index + 1;
                      final isHighlighted = s.state == highlightState;
                      final isTop = rank == 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHighlighted
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '#$rank',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isTop
                                      ? AppColors.warning
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                            if (isTop)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                s.state,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isHighlighted
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              DashboardStats.formatCompact(s.population),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
