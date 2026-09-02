import 'package:flutter/material.dart';
import '../models/state_population_data.dart';
import '../theme/app_colors.dart';
import '../utils/dashboard_stats.dart';

// ============================================================
// STATE RANKING SHEET
// ------------------------------------------------------------
// Shows states ranked by population for a single selected year,
// with controls to step through the full history available in
// the dataset. Defaults to the latest year.
//
// Pass the FULL multi-year list here (not a pre-filtered
// snapshot) - this widget does its own per-year filtering so all
// the historical data your dataset actually contains stays
// browsable instead of being thrown away.
// ============================================================

void showStateRankingSheet(
    BuildContext context, {
      required List<StatePopulationData> states,
      String? highlightState,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StateRankingSheet(
      allStates: states,
      highlightState: highlightState,
    ),
  );
}

class _StateRankingSheet extends StatefulWidget {
  final List<StatePopulationData> allStates;
  final String? highlightState;

  const _StateRankingSheet({required this.allStates, this.highlightState});

  @override
  State<_StateRankingSheet> createState() => _StateRankingSheetState();
}

class _StateRankingSheetState extends State<_StateRankingSheet> {
  late List<int> _availableYears; // ascending
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final years = widget.allStates.map((d) => d.date.year).toSet().toList()
      ..sort();
    _availableYears = years;
    _selectedYear = years.isNotEmpty ? years.last : DateTime.now().year;
  }

  // One row per state for the selected year, sorted by population desc.
  List<StatePopulationData> get _rankingForSelectedYear {
    final Map<String, StatePopulationData> byState = {};
    for (final d in widget.allStates) {
      if (d.date.year == _selectedYear) {
        byState[d.state] = d;
      }
    }
    final list = byState.values.toList()
      ..sort((a, b) => b.population.compareTo(a.population));
    return list;
  }

  bool get _canGoPrevious =>
      _availableYears.isNotEmpty && _selectedYear > _availableYears.first;
  bool get _canGoNext =>
      _availableYears.isNotEmpty && _selectedYear < _availableYears.last;

  void _stepYear(int delta) {
    final newYear = _selectedYear + delta;
    if (_availableYears.contains(newYear)) {
      setState(() => _selectedYear = newYear);
    }
  }

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _availableYears.reversed.map((y) {
            return ListTile(
              title: Text(y.toString()),
              trailing: y == _selectedYear
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, y),
            );
          }).toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedYear = picked);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _rankingForSelectedYear;
    final latestYear = _availableYears.isNotEmpty ? _availableYears.last : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'State Population Ranking',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (latestYear != null && _selectedYear != latestYear)
                    TextButton(
                      onPressed: () => setState(() => _selectedYear = latestYear),
                      child: const Text('Latest'),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${sorted.length} states, ranked by population',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),

              // ---- Year selector ----
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _canGoPrevious ? () => _stepYear(-1) : null,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Previous year',
                    ),
                    InkWell(
                      onTap: _availableYears.length > 1 ? _pickYear : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_selectedYear',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_availableYears.length > 1) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _canGoNext ? () => _stepYear(1) : null,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Next year',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: sorted.isEmpty
                    ? Center(
                  child: Text(
                    'No state data available for $_selectedYear.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final s = sorted[index];
                    final rank = index + 1;
                    final isHighlighted = s.state == widget.highlightState;
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
                            DashboardStats.formatStatePopulation(s.population),
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
  }
}
