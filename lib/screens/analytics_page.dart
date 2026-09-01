import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/section_title.dart';
import '../widgets/state_views.dart';
import '../widgets/statistic_card.dart';
import '../widgets/sparkline_chart.dart';
import '../widgets/watchlist_form_sheet.dart';
import '../services/api_service.dart';
import '../services/watchlist_service.dart';
import '../models/internet_penetration_data.dart';
import '../models/watchlist_alert.dart';
import '../utils/trend_predictor.dart';

// ============================================================
// CONNECTIVITY ANALYTICS PAGE
// ------------------------------------------------------------
// Module 2 features:
//   1. Interactive Data Filtering - metric chips + a From/To
//      quarter range picker (e.g. Q1 2025 -> Q3 2025) let the
//      user pick which series and exactly which period of
//      history to look at.
//   2. Digital Trend Prediction   - simple linear regression
//      over the selected metric + selected quarter range
//      forecasts the next period.
//   3. CRUD - "Analytics Watchlist": user-defined threshold
//      alerts on a metric, stored locally (Create/Read/Update/
//      Delete), evaluated live against the latest value.
// ============================================================

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService _apiService = ApiService();
  final WatchlistService _watchlistService = WatchlistService();

  bool _isLoading = true;
  String? _errorMessage;

  List<InternetPenetrationData> _data = [];
  List<WatchlistAlert> _watchlist = [];

  // ---- Interactive filtering state ----
  String _selectedMetric = WatchlistAlert.metricKeys.first; // fbbRate

  // From/To quarter range. Indices into _data (sorted oldest -> newest).
  // Null until data loads, at which point they default to the full range.
  int? _fromIndex;
  int? _toIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await _apiService.getInternetPenetration();
      final watchlist = await _watchlistService.getAll();

      data.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _data = data;
        _watchlist = watchlist;
        _isLoading = false;

        // Default the range to the full dataset on first load, or if a
        // refresh returned a differently-sized dataset.
        if (data.isNotEmpty) {
          _fromIndex ??= 0;
          _toIndex ??= data.length - 1;
          if (_fromIndex! > data.length - 1) _fromIndex = 0;
          if (_toIndex! > data.length - 1) _toIndex = data.length - 1;
          if (_fromIndex! > _toIndex!) _fromIndex = _toIndex;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics data. Pull down or tap retry.';
      });
    }
  }

  Future<void> _reloadWatchlistOnly() async {
    final watchlist = await _watchlistService.getAll();
    if (mounted) setState(() => _watchlist = watchlist);
  }

  // ============================================================
  // WATCHLIST CRUD HANDLERS
  // ============================================================

  Future<void> _createAlert() async {
    final result = await showWatchlistFormSheet(context);
    if (result != null) {
      await _watchlistService.create(result);
      await _reloadWatchlistOnly();
    }
  }

  Future<void> _editAlert(WatchlistAlert alert) async {
    final result = await showWatchlistFormSheet(context, existingAlert: alert);
    if (result != null) {
      await _watchlistService.update(result);
      await _reloadWatchlistOnly();
    }
  }

  Future<void> _deleteAlert(String id) async {
    setState(() => _watchlist.removeWhere((a) => a.id == id));
    await _watchlistService.delete(id);
  }

  // ============================================================
  // DATA HELPERS
  // ============================================================

  double _valueFor(InternetPenetrationData d, String metricKey) {
    switch (metricKey) {
      case 'fbbRate':
        return d.fbbRate;
      case 'mbbRate':
        return d.mbbRate;
      case 'mcRate':
        return d.mcRate;
      case 'ptvRate':
        return d.ptvRate;
      default:
        return 0;
    }
  }

  /// Formats a date as a quarter label, e.g. "Q1 2025".
  /// Your dataset's dates land on quarter-start months (Mar/Jun/Sep/Dec),
  /// so this maps month -> quarter number directly.
  String _quarterLabel(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    return 'Q$quarter ${date.year}';
  }

  List<InternetPenetrationData> get _rangedData {
    if (_data.isEmpty || _fromIndex == null || _toIndex == null) return _data;
    final from = _fromIndex!.clamp(0, _data.length - 1);
    final to = _toIndex!.clamp(0, _data.length - 1);
    return _data.sublist(from, to + 1);
  }

  List<double> get _selectedValues =>
      _rangedData.map((d) => _valueFor(d, _selectedMetric)).toList();

  bool _isTriggered(WatchlistAlert alert) {
    if (_data.isEmpty) return false;
    final latest = _valueFor(_data.last, alert.metricKey);
    return alert.direction == WatchlistDirection.above
        ? latest > alert.threshold
        : latest < alert.threshold;
  }

  // ============================================================
  // FROM/TO QUARTER PICKER
  // ============================================================

  Widget _buildQuarterRangePicker() {
    return Row(
      children: [
        Expanded(
          child: _QuarterDropdown(
            label: 'From',
            data: _data,
            selectedIndex: _fromIndex ?? 0,
            quarterLabelBuilder: _quarterLabel,
            onChanged: (index) {
              setState(() {
                _fromIndex = index;
                // Keep the range valid: "From" can't be after "To".
                if (_toIndex != null && _fromIndex! > _toIndex!) {
                  _toIndex = _fromIndex;
                }
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuarterDropdown(
            label: 'To',
            data: _data,
            selectedIndex: _toIndex ?? (_data.length - 1),
            quarterLabelBuilder: _quarterLabel,
            onChanged: (index) {
              setState(() {
                _toIndex = index;
                // Keep the range valid: "To" can't be before "From".
                if (_fromIndex != null && _toIndex! < _fromIndex!) {
                  _fromIndex = _toIndex;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadData);
    }

    if (_data.isEmpty) {
      return EmptyStateView(
        icon: Icons.bar_chart_outlined,
        message: 'No connectivity data available yet.',
      );
    }

    final values = _selectedValues;
    final latestValue = values.isNotEmpty ? values.last : 0.0;
    final firstValue = values.isNotEmpty ? values.first : 0.0;
    final change = latestValue - firstValue;
    final prediction = TrendPredictor.predictNext(values);

    final fromLabel = _rangedData.isNotEmpty
        ? _quarterLabel(_rangedData.first.date)
        : '--';
    final toLabel = _rangedData.isNotEmpty
        ? _quarterLabel(_rangedData.last.date)
        : '--';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            8,
            AppSpacing.screenPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connectivity Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Explore Malaysia\'s connectivity rates across metrics and '
                    'time periods.',
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade600),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ============================================================
              // FEATURE 1: INTERACTIVE DATA FILTERING
              // ============================================================
              const SectionTitle(
                title: 'Filter',
                subtitle: 'Choose a metric and a quarter range to explore',
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WatchlistAlert.metricKeys.map((key) {
                  final selected = _selectedMetric == key;
                  return ChoiceChip(
                    label: Text(WatchlistAlert.labelFor(key)),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedMetric = key),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              _buildQuarterRangePicker(),
              const SizedBox(height: 6),
              Text(
                'Showing $fromLabel – $toLabel (${_rangedData.length} quarters)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ============================================================
              // KEY FIGURES for the selected metric + range
              // ============================================================
              SectionTitle(title: WatchlistAlert.labelFor(_selectedMetric)),
              const SizedBox(height: 12),

              StatisticCard(
                title: 'Latest Value',
                value: latestValue.toStringAsFixed(1),
                subtitle: 'Per 100 inhabitants · $toLabel',
                icon: Icons.wifi,
                iconColor: AppColors.internet,
              ),
              const SizedBox(height: 12),

              StatisticCard(
                title: 'Change over selected range',
                value: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                subtitle: '$fromLabel to $toLabel',
                icon: change >= 0 ? Icons.trending_up : Icons.trending_down,
                iconColor: change >= 0 ? AppColors.success : AppColors.danger,
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ---- Trend chart ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${WatchlistAlert.labelFor(_selectedMetric)} Trend',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SparklineChart(values: values, color: AppColors.internet),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ============================================================
              // FEATURE 2: DIGITAL TREND PREDICTION
              // ============================================================
              const SectionTitle(
                title: 'Digital Trend Prediction',
                subtitle: 'Simple linear projection based on the selected range',
              ),
              const SizedBox(height: 12),

              if (prediction == null)
                const EmptyStateView(
                  icon: Icons.query_stats_outlined,
                  message: 'Not enough data points in this range to forecast. '
                      'Widen the From/To range above.',
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        prediction.isRising
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Predicted next quarter',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prediction.predictedNextValue.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${prediction.isRising ? 'Rising' : 'Falling'} '
                                  '≈ ${prediction.slopePerPeriod.toStringAsFixed(2)} per quarter '
                                  '(based on $fromLabel – $toLabel)',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ============================================================
              // CRUD: ANALYTICS WATCHLIST
              // ============================================================
              SectionTitle(
                title: 'Analytics Watchlist',
                subtitle: 'Get a visual flag when a metric crosses a threshold '
                    'you set. Tap the pencil to edit, trash to delete.',
                trailing: TextButton.icon(
                  onPressed: _createAlert,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),

              if (_watchlist.isEmpty)
                const EmptyStateView(
                  icon: Icons.visibility_outlined,
                  message: 'No alerts yet. Tap "Add" to watch a metric.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _watchlist.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final alert = _watchlist[index];
                    final triggered = _isTriggered(alert);
                    return _WatchlistTile(
                      alert: alert,
                      triggered: triggered,
                      onEdit: () => _editAlert(alert),
                      onDelete: () => _deleteAlert(alert.id),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// QUARTER DROPDOWN (used for the From/To range picker)
// ============================================================

class _QuarterDropdown extends StatelessWidget {
  final String label;
  final List<InternetPenetrationData> data;
  final int selectedIndex;
  final String Function(DateTime) quarterLabelBuilder;
  final ValueChanged<int> onChanged;

  const _QuarterDropdown({
    required this.label,
    required this.data,
    required this.selectedIndex,
    required this.quarterLabelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clampedIndex = selectedIndex.clamp(0, data.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: clampedIndex,
              items: List.generate(data.length, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(quarterLabelBuilder(data[index].date)),
                );
              }),
              onChanged: (index) {
                if (index != null) onChanged(index);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// WATCHLIST TILE
// ============================================================

class _WatchlistTile extends StatelessWidget {
  final WatchlistAlert alert;
  final bool triggered;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WatchlistTile({
    required this.alert,
    required this.triggered,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final directionText =
    alert.direction == WatchlistDirection.above ? 'above' : 'below';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: triggered
            ? AppColors.danger.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: triggered ? AppColors.danger.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            triggered ? Icons.notifications_active : Icons.notifications_none,
            color: triggered ? AppColors.danger : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.metricLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Alert when $directionText ${alert.threshold.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (triggered) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Threshold currently crossed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                ],
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
    );
  }
}
