import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/domain_data.dart';
import '../models/growth_bookmark.dart';
import '../services/api_service.dart';
import '../services/growth_bookmark_service.dart';
import '../theme/app_colors.dart';
import '../widgets/data_source_label.dart';
import '../widgets/growth_bookmark_card.dart';
import '../widgets/growth_hero_card.dart';
import '../widgets/growth_stat_tile.dart';
import '../widgets/growth_view_toggle.dart';

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  final ApiService _apiService = ApiService();
  final GrowthBookmarkService _bookmarkService = GrowthBookmarkService();

  List<DomainData> _domainData = [];
  List<GrowthBookmark> _bookmarks = [];

  bool _isLoading = true;
  String? _errorMessage;

  GrowthView _view = GrowthView.yearly;
  String? _selectedBookmarkId;

  static const int _maxBookmarks = 6;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBookmarks();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData() async {
    try {
      // IMPORTANT:
      // Growth Tracker uses the complete historical dataset.
      final data = await _apiService.getDomainsFullHistory();

      if (!mounted) return;

      setState(() {
        _domainData = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Growth Page Error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load growth data.';
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await _bookmarkService.getAll();

    if (!mounted) return;

    setState(() {
      _bookmarks = bookmarks;
    });
  }

  // ============================================================
  // DATA AGGREGATION
  // ============================================================

  // Only the pre-computed cumulative totals for "overall" (all TLDs
  // combined). The raw dataset also contains per-TLD rows (.com.my,
  // .net.my, ...) and a "new_net" series (monthly deltas) — mixing
  // those into a sum would double count and produce meaningless totals.
  List<DomainData> get _overallCumulative {
    final filtered = _domainData
        .where((d) => d.series == 'cumulative' && d.domain == 'overall')
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return filtered;
  }

  // Latest cumulative reading per year (not summed — each row is
  // already a running total as of that month).
  Map<int, int> get _cumulativeByYear {
    final result = <int, int>{};

    for (final data in _overallCumulative) {
      result[data.date.year] = data.registrations;
    }

    return result;
  }

  // Latest cumulative reading per month.
  Map<int, int> get _cumulativeByMonth {
    final result = <int, int>{};

    for (final data in _overallCumulative) {
      final key = data.date.year * 100 + data.date.month;
      result[key] = data.registrations;
    }

    return result;
  }

  // ============================================================
  // CURRENT TOTAL
  // ============================================================

  int get _currentTotal {
    final cumulative = _cumulativeByYear;

    if (cumulative.isEmpty) {
      return 0;
    }

    final years = cumulative.keys.toList()..sort();

    return cumulative[years.last]!;
  }

  // ============================================================
  // GROWTH CALCULATION FUNCTION
  // ============================================================

  double calculateGrowth(int current, int previous) {
    if (previous == 0) return 0;

    return ((current - previous) / previous) * 100;
  }

  double get _yoyGrowthPercent {
    final cumulative = _cumulativeByYear;
    final years = cumulative.keys.toList()..sort();

    if (years.length < 2) return 0;

    final current = cumulative[years.last]!;
    final previous = cumulative[years[years.length - 2]]!;

    return calculateGrowth(current, previous);
  }

  // ============================================================
  // GROWTH PERFORMANCE SUMMARY
  // ============================================================

  double get _highestGrowth {
    final data = _cumulativeByYear;
    final years = data.keys.toList()..sort();

    if (years.length < 2) return 0;

    double highest = double.negativeInfinity;

    for (int i = 1; i < years.length; i++) {
      final growth = calculateGrowth(
        data[years[i]]!,
        data[years[i - 1]]!,
      );

      if (growth > highest) {
        highest = growth;
      }
    }

    return highest;
  }

  double get _lowestGrowth {
    final data = _cumulativeByYear;
    final years = data.keys.toList()..sort();

    if (years.length < 2) return 0;

    double lowest = double.infinity;

    for (int i = 1; i < years.length; i++) {
      final growth = calculateGrowth(
        data[years[i]]!,
        data[years[i - 1]]!,
      );

      if (growth < lowest) {
        lowest = growth;
      }
    }

    return lowest;
  }

  double get _averageGrowth {
    final data = _cumulativeByYear;
    final years = data.keys.toList()..sort();

    if (years.length < 2) return 0;

    double total = 0;

    for (int i = 1; i < years.length; i++) {
      total += calculateGrowth(
        data[years[i]]!,
        data[years[i - 1]]!,
      );
    }

    return total / (years.length - 1);
  }

  String get _growthStatus {
    final growth = _yoyGrowthPercent;

    if (growth > 0) return 'Growing';
    if (growth < 0) return 'Declining';

    return 'Stable';
  }

  // ============================================================
  // CRUD: CREATE
  // ============================================================

  Future<void> _saveSnapshot() async {
    if (_bookmarks.length >= _maxBookmarks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can save up to 6 bookmarks only.'),
        ),
      );
      return;
    }

    final labelController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Save Growth Snapshot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Current total: ${_formatNumber(_currentTotal)} registrations',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: labelController,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Snapshot Name',
                    hintText: 'e.g. Semester Start',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateLabel,
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final now = DateTime.now();

                      await _bookmarkService.create(
                        GrowthBookmark(
                          id: now.microsecondsSinceEpoch.toString(),
                          label: labelController.text.trim(),
                          snapshotValue: _currentTotal,
                          savedAt: now,
                        ),
                      );

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }

                      await _loadBookmarks();
                    },
                    icon: const Icon(
                      Icons.bookmark_add,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Save Snapshot',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CRUD: UPDATE
  // ============================================================

  Future<void> _editBookmark(GrowthBookmark bookmark) async {
    final labelController =
    TextEditingController(text: bookmark.label);

    final valueController =
    TextEditingController(
      text: bookmark.snapshotValue.toString(),
    );

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Snapshot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: labelController,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Snapshot Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _validateLabel(
                        value,
                        excludingId: bookmark.id,
                      ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Snapshot Value',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateValue,
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final newValue =
                      int.parse(valueController.text.trim());

                      await _bookmarkService.update(
                        bookmark.copyWith(
                          label: labelController.text.trim(),
                          snapshotValue: newValue,
                        ),
                      );

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }

                      await _loadBookmarks();
                    },
                    icon: const Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CRUD: DELETE
  // ============================================================

  Future<void> _deleteBookmark(
      GrowthBookmark bookmark) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete snapshot?'),
        content: Text(
          'Remove "${bookmark.label}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _bookmarkService.delete(bookmark.id);

      if (_selectedBookmarkId == bookmark.id) {
        setState(() {
          _selectedBookmarkId = null;
        });
      }

      await _loadBookmarks();
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateLabel(
      String? value, {
        String? excludingId,
      }) {
    final label = value?.trim() ?? '';

    if (label.isEmpty) {
      return 'Label is required';
    }

    final duplicate = _bookmarks.any(
          (bookmark) =>
      bookmark.id != excludingId &&
          bookmark.label.trim().toLowerCase() ==
              label.toLowerCase(),
    );

    if (duplicate) {
      return 'A bookmark with this label already exists';
    }

    return null;
  }

  String? _validateValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Value is required';
    }

    final parsed = int.tryParse(value.trim());

    if (parsed == null) {
      return 'Enter a whole number';
    }

    if (parsed <= 0) {
      return 'Value must be greater than 0';
    }

    // NOTE: Intentionally no upper-bound check against _currentTotal.
    // Allowing a snapshot value higher than the live current total lets
    // you manually create/edit a snapshot representing an earlier,
    // higher figure - useful for demoing a "decline since snapshot"
    // comparison even in periods where live data only shows growth.

    return null;
  }

  // ============================================================
  // BOOKMARK COMPARISON
  // ============================================================

  void _toggleCompare(String bookmarkId) {
    setState(() {
      _selectedBookmarkId =
      _selectedBookmarkId == bookmarkId
          ? null
          : bookmarkId;
    });
  }

  // ============================================================
  // FORMAT NUMBER
  // ============================================================

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toString();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });

                  _loadData();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final cumulative =
    _view == GrowthView.yearly
        ? _cumulativeByYear
        : _cumulativeByMonth;

    final keys = cumulative.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          32,
        ),
        children: [

          // HERO
          GrowthHeroCard(
            currentTotal: _currentTotal,
            yoyGrowthPercent: _yoyGrowthPercent,
          ),

          const SizedBox(height: 24),

          // VIEW SELECTOR
          GrowthViewToggle(
            selected: _view,
            onChanged: (value) {
              setState(() {
                _view = value;
              });
            },
          ),

          const SizedBox(height: 24),

          // GRAPH TITLE
          const Text(
            'Domain Registration Growth',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _view == GrowthView.yearly
                ? 'Yearly cumulative registrations'
                : 'Monthly cumulative registrations',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 14),

          // GRAPH
          _buildGrowthChart(cumulative, keys),

          const SizedBox(height: 24),

          // STATISTICS
          Row(
            children: [
              Expanded(
                child: GrowthStatTile(
                  icon: Icons.trending_up,
                  label: 'Annual Growth',
                  value:
                  '${_yoyGrowthPercent >= 0 ? '+' : ''}'
                      '${_yoyGrowthPercent.toStringAsFixed(1)}%',
                  color: AppColors.success,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: GrowthStatTile(
                  icon: Icons.public,
                  label: 'Total Registrations',
                  value: _formatNumber(_currentTotal),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // PERFORMANCE SUMMARY
          _buildPerformanceSummary(),

          const SizedBox(height: 28),

          // BOOKMARK HEADER
          Row(
            children: [
              const Text(
                'Growth Snapshots',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              TextButton.icon(
                onPressed: _saveSnapshot,
                icon: const Icon(
                  Icons.bookmark_add_outlined,
                  size: 19,
                ),
                label: const Text('Save'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_bookmarks.isEmpty)
            _buildEmptyBookmarks()
          else
            ..._bookmarks.map(
                  (bookmark) => GrowthBookmarkCard(
                bookmark: bookmark,
                currentTotal: _currentTotal,
                isSelected:
                _selectedBookmarkId == bookmark.id,
                onTap: () =>
                    _toggleCompare(bookmark.id),
                onEdit: () =>
                    _editBookmark(bookmark),
                onDelete: () =>
                    _deleteBookmark(bookmark),
              ),
            ),

          const SizedBox(height: 20),

          const DataSourceLabel(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // CHART
  // ============================================================

  Widget _buildGrowthChart(
      Map<int, int> cumulative,
      List<int> keys,
      ) {
    if (keys.length < 2) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const Text(
          'Not enough data to display the growth chart.',
        ),
      );
    }

    final values = keys
        .map((key) => cumulative[key]!.toDouble())
        .toList();

    final maxY = values.reduce(
          (a, b) => a > b ? a : b,
    );

    final minY = values.reduce(
          (a, b) => a < b ? a : b,
    );

    final padding = (maxY - minY) * 0.15;

    return Container(
      // Bigger box + more internal breathing room so axis labels
      // and the curve itself aren't cramped.
      height: 340,
      padding: const EdgeInsets.fromLTRB(
        8,
        24,
        20,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppSpacing.cardRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: (minY - padding).clamp(0, double.infinity),
          maxY: maxY + padding,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
            maxY > 0 ? maxY / 4 : 1,
          ),

          borderData: FlBorderData(
            show: false,
          ),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatNumber(value.toInt()),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),

            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),

            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: _view == GrowthView.yearly
                    ? _calculateInterval(keys.length)
                    : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();

                  if (index < 0 ||
                      index >= keys.length) {
                    return const SizedBox();
                  }

                  final key = keys[index];

                  if (_view == GrowthView.yearly) {
                    return Padding(
                      padding:
                      const EdgeInsets.only(top: 10),
                      child: Text(
                        key.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }

                  // Monthly view: only label January of each
                  // year, so the axis always reads clean years
                  // instead of drifting months.
                  final month = key % 100;

                  if (month != 1) {
                    return const SizedBox();
                  }

                  final year = key ~/ 100;

                  return Padding(
                    padding:
                    const EdgeInsets.only(top: 10),
                    child: Text(
                      year.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,

            touchTooltipData:
            LineTouchTooltipData(
              getTooltipColor:
                  (_) => Colors.black87,

              getTooltipItems:
                  (touchedSpots) {
                return touchedSpots.map(
                      (spot) {
                    final index =
                    spot.x.round();

                    if (index < 0 ||
                        index >= keys.length) {
                      return null;
                    }

                    final key =
                    keys[index];

                    String period;

                    if (_view ==
                        GrowthView.yearly) {
                      period =
                          key.toString();
                    } else {
                      final month =
                          key % 100;

                      final year =
                          key ~/ 100;

                      period =
                      '${_monthName(month)} $year';
                    }

                    return LineTooltipItem(
                      '$period\n'
                          '${_formatNumber(spot.y.toInt())} registrations',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    );
                  },
                ).toList();
              },
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3,
              color: AppColors.primary,

              isStrokeCapRound: true,

              dotData: FlDotData(
                show: keys.length <= 12,
              ),

              belowBarData:
              BarAreaData(
                show: true,
              ),

              spots: [
                for (int i = 0;
                i < keys.length;
                i++)
                  FlSpot(
                    i.toDouble(),
                    cumulative[keys[i]]!
                        .toDouble(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(int length) {
    if (length <= 6) return 1;

    return (length / 6).ceilToDouble();
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // ============================================================
  // PERFORMANCE SUMMARY UI
  // ============================================================

  Widget _buildPerformanceSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppSpacing.cardRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Growth Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _performanceItem(
                  'Highest Growth',
                  '+${_highestGrowth.toStringAsFixed(1)}%',
                  Icons.arrow_upward,
                  AppColors.success,
                ),
              ),

              Expanded(
                child: _performanceItem(
                  'Lowest Growth',
                  '${_lowestGrowth.toStringAsFixed(1)}%',
                  Icons.arrow_downward,
                  AppColors.danger,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _performanceItem(
                  'Average Growth',
                  '${_averageGrowth.toStringAsFixed(1)}%',
                  Icons.analytics_outlined,
                  AppColors.primary,
                ),
              ),

              Expanded(
                child: _performanceItem(
                  'Current Status',
                  _growthStatus,
                  Icons.trending_up,
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceItem(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyBookmarks() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppSpacing.cardRadius,
        ),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_border,
            size: 36,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          const Text(
            'No growth snapshots yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Save a snapshot to compare future growth.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}