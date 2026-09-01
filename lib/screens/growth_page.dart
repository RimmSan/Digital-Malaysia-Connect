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
  GrowthView _view = GrowthView.yearly;
  String? _selectedBookmarkId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBookmarks();
  }

  // ------------------------------------------------------------
  // DATA
  // ------------------------------------------------------------
  Future<void> _loadData() async {
    try {
      final data = await _apiService.getDomains();
      if (!mounted) return;
      setState(() {
        _domainData = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await _bookmarkService.getAll();
    if (!mounted) return;
    setState(() => _bookmarks = bookmarks);
  }

  // ------------------------------------------------------------
  // AGGREGATION
  // ------------------------------------------------------------
  int get _currentTotal =>
      _domainData.fold<int>(0, (sum, d) => sum + d.registrations);

  Map<int, int> get _cumulativeByYear {
    final byYear = <int, int>{};
    for (final d in _domainData) {
      byYear[d.date.year] = (byYear[d.date.year] ?? 0) + d.registrations;
    }
    final years = byYear.keys.toList()..sort();
    final cumulative = <int, int>{};
    int running = 0;
    for (final y in years) {
      running += byYear[y]!;
      cumulative[y] = running;
    }
    return cumulative;
  }

  Map<int, int> get _cumulativeByMonth {
    final byMonth = <int, int>{};
    for (final d in _domainData) {
      final key = d.date.year * 100 + d.date.month;
      byMonth[key] = (byMonth[key] ?? 0) + d.registrations;
    }
    final keys = byMonth.keys.toList()..sort();
    final cumulative = <int, int>{};
    int running = 0;
    for (final k in keys) {
      running += byMonth[k]!;
      cumulative[k] = running;
    }
    return cumulative;
  }

  double get _yoyGrowthPercent {
    final cumulative = _cumulativeByYear;
    final years = cumulative.keys.toList()..sort();
    if (years.length < 2) return 0;
    final latest = cumulative[years.last]!;
    final previous = cumulative[years[years.length - 2]]!;
    if (previous == 0) return 0;
    return ((latest - previous) / previous) * 100;
  }

  // ------------------------------------------------------------
  // CRUD: Create
  // ------------------------------------------------------------
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
                const Text('Save Snapshot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Current total: ${(_currentTotal / 1000000).toStringAsFixed(2)}M registrations',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: labelController,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g. Before semester break',
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
                      if (!formKey.currentState!.validate()) return;

                      final now = DateTime.now();
                      await _bookmarkService.create(GrowthBookmark(
                        id: now.microsecondsSinceEpoch.toString(),
                        label: labelController.text.trim(),
                        snapshotValue: _currentTotal,
                        savedAt: now,
                      ));

                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      await _loadBookmarks();
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // CRUD: Update
  // ------------------------------------------------------------
  Future<void> _editBookmark(GrowthBookmark bookmark) async {
    final labelController = TextEditingController(text: bookmark.label);
    final valueController =
    TextEditingController(text: bookmark.snapshotValue.toString());

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
                  'Edit Bookmark',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Edit Label
                TextFormField(
                  controller: labelController,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateLabel(
                    value,
                    excludingId: bookmark.id,
                  ),
                ),

                const SizedBox(height: 16),

                // Edit Snapshot Value
                TextFormField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Snapshot Value',
                    hintText: 'Enter registration value',
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
                      if (!formKey.currentState!.validate()) return;

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

  // ------------------------------------------------------------
  // CRUD: Delete
  // ------------------------------------------------------------
  Future<void> _deleteBookmark(GrowthBookmark bookmark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete bookmark?'),
        content: Text('Remove "${bookmark.label}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _bookmarkService.delete(bookmark.id);
      if (_selectedBookmarkId == bookmark.id) {
        setState(() => _selectedBookmarkId = null);
      }
      await _loadBookmarks();
    }
  }

  // ------------------------------------------------------------
  // VALIDATION HELPERS
  // ------------------------------------------------------------
  static const int _maxBookmarks = 6;

  int _wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  String? _validateLabel(String? value, {String? excludingId}) {
    final label = value?.trim() ?? '';

    if (label.isEmpty) {
      return 'Label is required';
    }

    // Duplicate check (case-insensitive), ignoring the bookmark being edited
    final isDuplicate = _bookmarks.any((b) =>
    b.id != excludingId && b.label.trim().toLowerCase() == label.toLowerCase());
    if (isDuplicate) {
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

    if (parsed > _currentTotal) {
      return 'Value cannot be greater than the current total registration';
    }

    return null;
  }

  // ------------------------------------------------------------
  // FUNCTION: Comparison Highlighter
  // ------------------------------------------------------------
  void _toggleCompare(String bookmarkId) {
    setState(() {
      _selectedBookmarkId = _selectedBookmarkId == bookmarkId ? null : bookmarkId;
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cumulative =
    _view == GrowthView.yearly ? _cumulativeByYear : _cumulativeByMonth;
    final keys = cumulative.keys.toList();
    final yoy = _yoyGrowthPercent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), // more bottom breathing room
      children: [
        GrowthHeroCard(currentTotal: _currentTotal, yoyGrowthPercent: yoy),
        const SizedBox(height: 28), // was 20
        GrowthViewToggle(
          selected: _view,
          onChanged: (value) => setState(() => _view = value),
        ),
        const SizedBox(height: 24), // was 16
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4), // aligns text nicely with cards
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Domain Registration Trend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Cumulative .MY registrations',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        const SizedBox(height: 16), // was 12
        Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 8), // breathing room inside chart card
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(
            height: 220,
            child: keys.length < 2
                ? const Center(child: Text('Not enough data to chart yet'))
                : LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= keys.length) {
                          return const SizedBox();
                        }
                        final key = keys[idx];
                        final label = _view == GrowthView.yearly
                            ? '$key'
                            : '${key % 100}/${key ~/ 100 % 100}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(label, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    spots: [
                      for (int i = 0; i < keys.length; i++)
                        FlSpot(i.toDouble(), cumulative[keys[i]]!.toDouble()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28), // was 20
        Row(
          children: [
            Expanded(
              child: GrowthStatTile(
                icon: Icons.show_chart,
                label: 'Annual Growth Rate',
                value: '${yoy >= 0 ? '+' : ''}${yoy.toStringAsFixed(1)}%',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 14), // was 12
            Expanded(
              child: GrowthStatTile(
                icon: Icons.public,
                label: 'Total Registrations',
                value: '${(_currentTotal / 1000000).toStringAsFixed(2)}M',
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Text('Growth Bookmarks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _saveSnapshot,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save Snapshot'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16), // was 12
        if (_bookmarks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.bookmark_border, size: 32, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No bookmarks yet. Save a snapshot to compare progress over time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ..._bookmarks.map((bookmark) => GrowthBookmarkCard(
            bookmark: bookmark,
            currentTotal: _currentTotal,
            isSelected: _selectedBookmarkId == bookmark.id,
            onTap: () => _toggleCompare(bookmark.id),
            onEdit: () => _editBookmark(bookmark),
            onDelete: () => _deleteBookmark(bookmark),
          )),

        const SizedBox(height: 16), // was 8
        const DataSourceLabel(),
        const SizedBox(height: 32), // was 24
      ],
    );
  }
}