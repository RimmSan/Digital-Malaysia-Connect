import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/domain_data.dart';
import '../models/growth_target.dart';
import '../services/api_service.dart';
import '../services/growth_cache_service.dart';
import '../services/growth_target_service.dart';
import '../theme/app_colors.dart';

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  final ApiService _apiService = ApiService();
  final GrowthCacheService _cacheService = GrowthCacheService();
  final GrowthTargetService _targetService = GrowthTargetService();

  List<DomainData> _domainData = [];
  List<GrowthTarget> _targets = [];

  DateTime? _lastUpdated;
  bool _isOffline = false;
  bool _isLoading = true;
  bool _demoMode = false;

  // Demo-only simulated bump on top of real cumulative total,
  // so Auto Refresh + Milestone Achieved can be shown live
  // without waiting for data.gov.my to actually publish new data.
  int _demoBump = 0;

  Timer? _refreshTimer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _loadTargets();
    _fetchData(showLoading: true);
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DATA FETCH (Automatic Refresh + Offline fallback)
  // ------------------------------------------------------------
  Future<void> _fetchData({required bool showLoading}) async {
    if (showLoading) setState(() => _isLoading = true);

    try {
      final data = await _apiService.getDomains();
      await _cacheService.save(data);

      if (!mounted) return;
      setState(() {
        _domainData = data;
        _lastUpdated = DateTime.now();
        _isOffline = false;
        _isLoading = false;
        if (_demoMode) {
          _demoBump += 20000 + _random.nextInt(60000);
        }
      });

      if (mounted && !showLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text('🔄 Synced with data.gov.my'),
          ),
        );
      }
    } catch (_) {
      final cached = await _cacheService.load();
      if (!mounted) return;

      if (cached != null) {
        setState(() {
          _domainData = cached.$1;
          _lastUpdated = cached.$2;
          _isOffline = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTargets() async {
    final targets = await _targetService.getAll();
    if (!mounted) return;
    setState(() => _targets = targets);
  }

  // ------------------------------------------------------------
  // AGGREGATION: cumulative registrations by year
  // ------------------------------------------------------------
  int get _currentTotal {
    final real = _domainData.fold<int>(0, (sum, d) => sum + d.registrations);
    return real + _demoBump;
  }

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
    if (cumulative.isNotEmpty && _demoBump > 0) {
      final lastYear = cumulative.keys.last;
      cumulative[lastYear] = cumulative[lastYear]! + _demoBump;
    }
    return cumulative;
  }

  String _timeAgo(DateTime? time) {
    if (time == null) return '--:--:--';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------
  // CRUD: Add / Edit target
  // ------------------------------------------------------------
  Future<void> _openTargetForm({GrowthTarget? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final valueController = TextEditingController(
      text: existing != null ? existing.targetValue.toString() : '',
    );
    DateTime selectedDeadline =
        existing?.deadline ?? DateTime.now().add(const Duration(days: 30));
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'New Growth Target' : 'Edit Growth Target',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: labelController,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        hintText: 'e.g. Reach 2M .MY domains',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Label is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target registrations',
                        hintText: 'e.g. 2000000',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Target value is required';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null) {
                          return 'Enter a whole number';
                        }
                        if (parsed <= 0) {
                          return 'Target must be greater than 0';
                        }
                        if (parsed <= _currentTotal) {
                          return 'Target must be above current total (${_currentTotal})';
                        }
                        if (parsed > 100000000) {
                          return 'Target is unrealistically high';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Deadline: ${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDeadline,
                              firstDate: DateTime.now().add(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDeadline = picked);
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final now = DateTime.now();
                          if (existing == null) {
                            await _targetService.create(GrowthTarget(
                              id: now.microsecondsSinceEpoch.toString(),
                              label: labelController.text.trim(),
                              targetValue: int.parse(valueController.text.trim()),
                              deadline: selectedDeadline,
                              createdAt: now,
                              updatedAt: now,
                            ));
                          } else {
                            await _targetService.update(existing.copyWith(
                              label: labelController.text.trim(),
                              targetValue: int.parse(valueController.text.trim()),
                              deadline: selectedDeadline,
                              updatedAt: now,
                            ));
                          }

                          if (context.mounted) Navigator.pop(context);
                          await _loadTargets();
                        },
                        child: Text(
                          existing == null ? 'Add Target' : 'Save Changes',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTarget(GrowthTarget target) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete target?'),
        content: Text('Remove "${target.label}"? This cannot be undone.'),
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
      await _targetService.delete(target.id);
      await _loadTargets();
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cumulative = _cumulativeByYear;
    final years = cumulative.keys.toList();

    return RefreshIndicator(
      onRefresh: () => _fetchData(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatusBar(),
          const SizedBox(height: 20),
          _buildTotalCard(),
          const SizedBox(height: 24),
          const Text('Domain Registration Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: years.length < 2
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
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= years.length) {
                          return const SizedBox();
                        }
                        return Text('${years[idx]}',
                            style: const TextStyle(fontSize: 11));
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
                      for (int i = 0; i < years.length; i++)
                        FlSpot(i.toDouble(), cumulative[years[i]]!.toDouble()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildTargetsHeader(),
          const SizedBox(height: 12),
          if (_targets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No growth targets yet. Tap "Add Target" to set one.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ..._targets.map(_buildTargetCard),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Row(
      children: [
        Icon(
          _isOffline ? Icons.cloud_off : Icons.cloud_done,
          size: 18,
          color: _isOffline ? AppColors.warning : AppColors.success,
        ),
        const SizedBox(width: 6),
        Text(
          _isOffline ? 'Offline (showing cached data)' : 'Last updated: ${_timeAgo(_lastUpdated)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const Spacer(),
        const Text('Demo Mode', style: TextStyle(fontSize: 12)),
        Switch(
          value: _demoMode,
          onChanged: (value) => setState(() => _demoMode = value),
        ),
      ],
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total .MY Registrations',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '${(_currentTotal / 1000000).toStringAsFixed(2)}M',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.trending_up, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildTargetsHeader() {
    return Row(
      children: [
        const Text('Growth Targets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _openTargetForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Target'),
        ),
      ],
    );
  }

  Widget _buildTargetCard(GrowthTarget target) {
    final achieved = _currentTotal >= target.targetValue;
    final progress = (_currentTotal / target.targetValue).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(target.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (achieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🎉 Achieved',
                        style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _openTargetForm(existing: target),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteTarget(target),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: achieved ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_currentTotal / 1000000).toStringAsFixed(2)}M / '
                  '${(target.targetValue / 1000000).toStringAsFixed(2)}M · '
                  'Deadline ${target.deadline.day}/${target.deadline.month}/${target.deadline.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}