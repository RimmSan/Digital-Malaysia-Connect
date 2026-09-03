import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/section_title.dart';
import '../widgets/state_views.dart';
import '../widgets/statistic_card.dart';
import '../widgets/watchlist_form_sheet.dart';
import '../services/api_service.dart';
import '../services/watchlist_service.dart';
import '../models/internet_penetration_data.dart';
import '../models/watchlist_alert.dart';
import '../utils/trend_predictor.dart';
import '../utils/chart_exporter.dart';

enum _ChartStyle { line, bar }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService _apiService = ApiService();
  final WatchlistService _watchlistService = WatchlistService();
  final GlobalKey _chartKey = GlobalKey();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isExporting = false;

  List<InternetPenetrationData> _data = [];
  List<WatchlistAlert> _watchlist = [];

  String _selectedMetric = WatchlistAlert.metricKeys.first;
  int? _fromIndex;
  int? _toIndex;
  int _forecastQuarters = 4;
  _ChartStyle _chartStyle = _ChartStyle.line;

  static const List<int> _forecastOptions = [2, 4, 6];

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
        _errorMessage = 'Failed to load analytics data.';
      });
    }
  }

  Future<void> _reloadWatchlist() async {
    final watchlist = await _watchlistService.getAll();
    if (mounted) setState(() => _watchlist = watchlist);
  }

  Future<void> _createAlert() async {
    final result = await showWatchlistFormSheet(context, existingAlerts: _watchlist);
    if (result != null) {
      await _watchlistService.create(result);
      await _reloadWatchlist();
    }
  }

  Future<void> _editAlert(WatchlistAlert alert) async {
    final result = await showWatchlistFormSheet(context, existingAlert: alert, existingAlerts: _watchlist);
    if (result != null) {
      await _watchlistService.update(result);
      await _reloadWatchlist();
    }
  }

  Future<void> _deleteAlert(String id) async {
    setState(() => _watchlist.removeWhere((a) => a.id == id));
    await _watchlistService.delete(id);
  }

  double _valueFor(InternetPenetrationData d, String key) {
    switch (key) {
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

  String _quarterLabel(DateTime date) => 'Q${((date.month - 1) ~/ 3) + 1} ${date.year}';

  String _fileSafeMetricName() => WatchlistAlert.labelFor(_selectedMetric).toLowerCase().replaceAll(' ', '_');

  String _quarterLabelAfter(DateTime date, int ahead) {
    final totalMonths = date.month - 1 + (ahead * 3);
    final year = date.year + (totalMonths ~/ 12);
    final quarter = ((totalMonths % 12) ~/ 3) + 1;
    return 'Q$quarter $year';
  }

  List<InternetPenetrationData> get _rangedData {
    if (_data.isEmpty || _fromIndex == null || _toIndex == null) return _data;
    return _data.sublist(_fromIndex!.clamp(0, _data.length - 1), _toIndex!.clamp(0, _data.length - 1) + 1);
  }

  List<double> get _selectedValues => _rangedData.map((d) => _valueFor(d, _selectedMetric)).toList();

  bool _isTriggered(WatchlistAlert alert) {
    if (_data.isEmpty) return false;
    final latest = _valueFor(_data.last, alert.metricKey);
    return alert.direction == WatchlistDirection.above ? latest > alert.threshold : latest < alert.threshold;
  }

  Future<void> _exportImage() async {
    setState(() => _isExporting = true);
    try {
      await ChartExporter.exportWidgetAsImage(boundaryKey: _chartKey, fileName: '${_fileSafeMetricName()}_trend_prediction');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel(TrendPrediction? prediction, DateTime? lastDate) async {
    setState(() => _isExporting = true);
    try {
      final forecastRows = <MapEntry<String, double>>[];
      if (prediction != null && lastDate != null) {
        for (int i = 0; i < prediction.forecastSeries.length; i++) {
          forecastRows.add(MapEntry(_quarterLabelAfter(lastDate, i + 1), prediction.forecastSeries[i]));
        }
      }
      await ChartExporter.exportDataAsExcel(
        data: _rangedData,
        metricLabel: WatchlistAlert.labelFor(_selectedMetric),
        metricKey: _selectedMetric,
        forecastRows: forecastRows,
        fileName: '${_fileSafeMetricName()}_data_export',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildQuarterDropdown(String label, int selected, ValueChanged<int> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<int>(
        value: selected.clamp(0, _data.length - 1),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: List.generate(_data.length, (i) => DropdownMenuItem(value: i, child: Text(_quarterLabel(_data[i].date)))),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _buildChart(List<double> values, List<double> forecast, List<String> labels, List<String> forecastLabels) {
    final barGroups = <BarChartGroupData>[];
    final lineSpots = <FlSpot>[];
    final forecastSpots = <FlSpot>[];
    final allLabels = [...labels, ...forecastLabels];

    for (int i = 0; i < values.length; i++) {
      lineSpots.add(FlSpot(i.toDouble(), values[i]));
      barGroups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: values[i], color: AppColors.internet, width: 14, borderRadius: BorderRadius.circular(4)),
      ]));
    }
    for (int i = 0; i < forecast.length; i++) {
      final x = (values.length + i).toDouble();
      forecastSpots.add(FlSpot(x, forecast[i]));
      barGroups.add(BarChartGroupData(x: x.toInt(), barRods: [
        BarChartRodData(toY: forecast[i], color: AppColors.warning, width: 14, borderRadius: BorderRadius.circular(4)),
      ]));
    }
    if (forecastSpots.isNotEmpty) forecastSpots.insert(0, lineSpots.last);

    Widget bottomLabel(double value, TitleMeta meta) {
      final index = value.toInt();
      if (index < 0 || index >= allLabels.length) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(allLabels[index], style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      );
    }

    return SizedBox(
      height: 280,
      child: _chartStyle == _ChartStyle.line
          ? LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: (allLabels.length / 6).clamp(1, allLabels.length).toDouble(), getTitlesWidget: bottomLabel)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem('${s.y.toStringAsFixed(1)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: lineSpots,
              isCurved: true,
              color: AppColors.internet,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.internet.withValues(alpha: 0.12)),
            ),
            if (forecastSpots.isNotEmpty)
              LineChartBarData(
                spots: forecastSpots,
                isCurved: true,
                color: AppColors.warning,
                barWidth: 3,
                dashArray: [6, 4],
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppColors.warning, strokeWidth: 2, strokeColor: Colors.white),
                ),
              ),
          ],
        ),
      )
          : BarChart(
        BarChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: (allLabels.length / 6).clamp(1, allLabels.length).toDouble(), getTitlesWidget: bottomLabel)),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${rod.toY.toStringAsFixed(1)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();
    if (_errorMessage != null) return ErrorView(message: _errorMessage!, onRetry: _loadData);
    if (_data.isEmpty) return const EmptyStateView(message: 'No connectivity data available yet.');

    final values = _selectedValues;
    final latestValue = values.isNotEmpty ? values.last : 0.0;
    final change = values.isNotEmpty ? latestValue - values.first : 0.0;
    final prediction = TrendPredictor.predictNext(values, periodsAhead: _forecastQuarters);
    final lastDate = _rangedData.isNotEmpty ? _rangedData.last.date : null;
    final fromLabel = _rangedData.isNotEmpty ? _quarterLabel(_rangedData.first.date) : '--';
    final toLabel = _rangedData.isNotEmpty ? _quarterLabel(_rangedData.last.date) : '--';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8, AppSpacing.screenPadding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Connectivity Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sectionGap),

              const SectionTitle(title: 'Filter'),
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
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey.shade700),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuarterDropdown('From', _fromIndex ?? 0, (v) => setState(() {
                    _fromIndex = v;
                    if (_toIndex != null && v > _toIndex!) _toIndex = v;
                  })),
                  const SizedBox(width: 12),
                  _buildQuarterDropdown('To', _toIndex ?? (_data.length - 1), (v) => setState(() {
                    _toIndex = v;
                    if (_fromIndex != null && v < _fromIndex!) _fromIndex = v;
                  })),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),
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
              const SectionTitle(title: 'Digital Trend Prediction'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Forecast: ', style: TextStyle(color: Colors.grey.shade600)),
                  ..._forecastOptions.map((q) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$q quarters'),
                      selected: _forecastQuarters == q,
                      onSelected: (_) => setState(() => _forecastQuarters = q),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _forecastQuarters == q ? Colors.white : Colors.grey.shade700),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Line'),
                      selected: _chartStyle == _ChartStyle.line,
                      onSelected: (_) => setState(() => _chartStyle = _ChartStyle.line),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _chartStyle == _ChartStyle.line ? Colors.white : Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Bar'),
                      selected: _chartStyle == _ChartStyle.bar,
                      onSelected: (_) => setState(() => _chartStyle = _ChartStyle.bar),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _chartStyle == _ChartStyle.bar ? Colors.white : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (prediction == null)
                const EmptyStateView(message: 'Not enough data points to forecast.')
              else ...[
                RepaintBoundary(
                  key: _chartKey,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surface,
                    child: _buildChart(
                      values,
                      prediction.forecastSeries,
                      _rangedData.map((d) => _quarterLabel(d.date)).toList(),
                      lastDate == null ? [] : List.generate(prediction.forecastSeries.length, (i) => _quarterLabelAfter(lastDate, i + 1)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isExporting ? null : _exportImage,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Save as Image'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isExporting ? null : () => _exportExcel(prediction, lastDate),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Export Excel'),
                      ),
                    ),
                  ],
                ),
                if (_isExporting) const Padding(padding: EdgeInsets.only(top: 10), child: Center(child: CircularProgressIndicator())),
                const SizedBox(height: 12),
                StatisticCard(
                  title: 'Predicted next quarter',
                  value: prediction.predictedNextValue.toStringAsFixed(1),
                  subtitle: '${prediction.isRising ? 'Rising' : 'Falling'} ≈ ${prediction.slopePerPeriod.toStringAsFixed(2)} per quarter',
                  icon: prediction.isRising ? Icons.trending_up : Icons.trending_down,
                  iconColor: AppColors.warning,
                ),
                const SizedBox(height: 12),
                if (lastDate != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Forecast breakdown', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        for (int i = 0; i < prediction.forecastSeries.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_quarterLabelAfter(lastDate, i + 1), style: TextStyle(color: Colors.grey.shade700)),
                                Text(prediction.forecastSeries[i].toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: AppSpacing.sectionGap),
              SectionTitle(
                title: 'Analytics Watchlist',
                trailing: TextButton.icon(onPressed: _createAlert, icon: const Icon(Icons.add), label: const Text('Add')),
              ),
              const SizedBox(height: 12),
              if (_watchlist.isEmpty)
                const EmptyStateView(message: 'No alerts yet. Tap "Add" to watch a metric.')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _watchlist.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final alert = _watchlist[index];
                    final triggered = _isTriggered(alert);
                    final direction = alert.direction == WatchlistDirection.above ? 'above' : 'below';
                    return ListTile(
                      tileColor: triggered ? AppColors.danger.withValues(alpha: 0.08) : Theme.of(context).colorScheme.surface,
                      leading: Icon(triggered ? Icons.notifications_active : Icons.notifications_none, color: triggered ? AppColors.danger : Colors.grey),
                      title: Text(alert.metricLabel),
                      subtitle: Text('Alert when $direction ${alert.threshold.toStringAsFixed(0)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editAlert(alert)),
                          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteAlert(alert.id)),
                        ],
                      ),
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