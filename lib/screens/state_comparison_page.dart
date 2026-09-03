import 'package:flutter/material.dart';

import '../models/state_population_data.dart';
import '../models/intelligence_report.dart';
import '../services/api_service.dart';
import '../services/intelligence_reports_service.dart';
import 'saved_intelligence_reports_page.dart';

class StateComparisonPage extends StatefulWidget {
  const StateComparisonPage({super.key});

  @override
  State<StateComparisonPage> createState() =>
      _StateComparisonPageState();
}

class _StateComparisonPageState extends State<StateComparisonPage> {
  final ApiService _apiService = ApiService();

  final IntelligenceReportsService _reportsService =
  IntelligenceReportsService();

  bool _isLoading = true;
  bool _isSavingReport = false;

  String? _errorMessage;

  List<StatePopulationData> _allPopulationData = [];
  List<StatePopulationData> _latestStates = [];

  String? _stateA;
  String? _stateB;

  bool _showComparison = false;

  static const int _maxSavedReports = 50;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD STATE DATA
  // ============================================================

  Future<void> _loadData() async {
    try {
      final populationData =
      await _apiService.getStatePopulation();

      final Map<String, StatePopulationData> latestByState = {};

      for (final record in populationData) {
        final current = latestByState[record.state];

        if (current == null ||
            record.date.isAfter(current.date)) {
          latestByState[record.state] = record;
        }
      }

      final latestStates = latestByState.values.toList()
        ..sort(
              (a, b) => b.population.compareTo(a.population),
        );

      if (!mounted) return;

      setState(() {
        _allPopulationData = populationData;
        _latestStates = latestStates;

        if (latestStates.length >= 2) {
          _stateA = latestStates[0].state;
          _stateB = latestStates[1].state;
        }

        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // GET LATEST RECORD
  // ============================================================

  StatePopulationData? _getLatestRecord(String state) {
    final records = _allPopulationData
        .where(
          (record) => record.state == state,
    )
        .toList();

    if (records.isEmpty) {
      return null;
    }

    records.sort(
          (a, b) => b.date.compareTo(a.date),
    );

    return records.first;
  }

  // ============================================================
  // GET PREVIOUS YEAR RECORD
  // ============================================================

  StatePopulationData? _getPreviousYearRecord(
      String state,
      StatePopulationData latest,
      ) {
    final previousYear = latest.date.year - 1;

    final records = _allPopulationData.where(
          (record) =>
      record.state == state &&
          record.date.year == previousYear,
    );

    if (records.isEmpty) {
      return null;
    }

    return records.first;
  }

  // ============================================================
  // CALCULATE GROWTH
  // ============================================================

  double? _calculateGrowth(
      StatePopulationData latest,
      StatePopulationData? previous,
      ) {
    if (previous == null ||
        previous.population == 0) {
      return null;
    }

    return ((latest.population - previous.population) /
        previous.population) *
        100;
  }

  // ============================================================
  // GET RANKING
  // ============================================================

  int _getRanking(String state) {
    final index = _latestStates.indexWhere(
          (record) => record.state == state,
    );

    if (index == -1) {
      return 0;
    }

    return index + 1;
  }

  // ============================================================
  // FORMAT POPULATION
  // ============================================================

  String _formatPopulation(double population) {
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(2)}M';
    }

    return '${population.toStringAsFixed(1)}K';
  }

  // ============================================================
  // FORMAT GROWTH
  // ============================================================

  String _formatGrowth(double? growth) {
    if (growth == null) {
      return 'N/A';
    }

    return '${growth >= 0 ? '+' : ''}'
        '${growth.toStringAsFixed(2)}%';
  }

  // ============================================================
  // COMPARE STATES
  // ============================================================

  void _compareStates() {
    if (_stateA == null || _stateB == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select two states.',
          ),
        ),
      );

      _forceDismissSnackBar();
      return;
    }

    if (_stateA == _stateB) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select two different states.',
          ),
        ),
      );

      _forceDismissSnackBar();
      return;
    }

    final stateAExists = _latestStates.any(
          (state) => state.state == _stateA,
    );

    final stateBExists = _latestStates.any(
          (state) => state.state == _stateB,
    );

    if (!stateAExists || !stateBExists) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'One or more selected states are invalid.',
          ),
        ),
      );

      _forceDismissSnackBar();
      return;
    }

    setState(() {
      _showComparison = true;
    });
  }

  // ============================================================
  // FORCE DISMISS SNACKBAR
  // ============================================================

  void _forceDismissSnackBar() {
    Future.delayed(
      const Duration(seconds: 3),
          () {
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    );
  }

  // ============================================================
  // BUILD COMPARISON INSIGHT
  // ============================================================

  String _buildInsight(
      StatePopulationData a,
      StatePopulationData b,
      int rankA,
      int rankB,
      ) {
    final difference =
    (a.population - b.population).abs();

    final largerState =
    a.population >= b.population ? a.state : b.state;

    final smallerState =
    a.population >= b.population ? b.state : a.state;

    final betterRankState =
    rankA <= rankB ? a.state : b.state;

    final formattedDifference =
    _formatPopulation(difference);

    return '$largerState has approximately '
        '$formattedDifference more residents than '
        '$smallerState. '
        '$betterRankState ranks higher nationally '
        'by population.';
  }

  // ============================================================
  // SAVE COMPARISON REPORT
  // ============================================================

  Future<void> _saveComparisonReport({
    required StatePopulationData stateA,
    required StatePopulationData stateB,
    required int rankA,
    required int rankB,
  }) async {
    if (_isSavingReport) {
      return;
    }

    if (stateA.state == stateB.state) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select two different states.',
          ),
        ),
      );

      _forceDismissSnackBar();
      return;
    }

    setState(() {
      _isSavingReport = true;
    });

    try {
      final existingReports =
      await _reportsService.getAll();

      // ========================================================
      // DUPLICATE CHECK
      // ========================================================

      final duplicateExists = existingReports.any(
            (report) {
          if (report.reportType != 'State Comparison') {
            return false;
          }

          final sameOrder =
              report.stateA == stateA.state &&
                  report.stateB == stateB.state;

          final reversedOrder =
              report.stateA == stateB.state &&
                  report.stateB == stateA.state;

          return sameOrder || reversedOrder;
        },
      );

      if (duplicateExists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This comparison report has already been saved.',
            ),
          ),
        );

        _forceDismissSnackBar();
        return;
      }

      // ========================================================
      // MAXIMUM 50 REPORTS
      // ========================================================

      if (existingReports.length >= _maxSavedReports) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maximum of 50 saved reports reached. '
                  'Delete an existing report to save a new one.',
            ),
          ),
        );

        _forceDismissSnackBar();
        return;
      }

      // ========================================================
      // CREATE REPORT
      // ========================================================

      final now = DateTime.now();

      final insight = _buildInsight(
        stateA,
        stateB,
        rankA,
        rankB,
      );

      final report = IntelligenceReport(
        id: now.microsecondsSinceEpoch.toString(),
        title:
        '${stateA.state} vs ${stateB.state} Comparison',
        stateA: stateA.state,
        stateB: stateB.state,
        reportType: 'State Comparison',
        insight: insight,
        note: '',
        createdAt: now,
        updatedAt: now,
      );

      await _reportsService.create(report);

      if (!mounted) return;

      // ========================================================
      // SUCCESS SNACKBAR
      // ========================================================

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Comparison report saved successfully.',
          ),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .hideCurrentSnackBar();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const SavedIntelligenceReportsPage(),
                ),
              );
            },
          ),
        ),
      );

      // IMPORTANT:
      // We manually dismiss it instead of relying on
      // SnackBar.duration.
      _forceDismissSnackBar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save comparison report. '
                'Please try again.',
          ),
        ),
      );

      _forceDismissSnackBar();
    } finally {
      if (mounted) {
        setState(() {
          _isSavingReport = false;
        });
      }
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'State Comparison Tool',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'State Comparison Tool',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 50,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Unable to load comparison data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                FilledButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });

                    _loadData();
                  },
                  child: const Text(
                    'Retry',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final latestA = _stateA == null
        ? null
        : _getLatestRecord(_stateA!);

    final latestB = _stateB == null
        ? null
        : _getLatestRecord(_stateB!);

    final previousA = latestA == null
        ? null
        : _getPreviousYearRecord(
      latestA.state,
      latestA,
    );

    final previousB = latestB == null
        ? null
        : _getPreviousYearRecord(
      latestB.state,
      latestB,
    );

    final growthA = latestA == null
        ? null
        : _calculateGrowth(
      latestA,
      previousA,
    );

    final growthB = latestB == null
        ? null
        : _calculateGrowth(
      latestB,
      previousB,
    );

    final rankA =
    _stateA == null ? 0 : _getRanking(_stateA!);

    final rankB =
    _stateB == null ? 0 : _getRanking(_stateB!);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'State Comparison Tool',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Compare Malaysian States',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Select two states to compare their latest '
                'population, ranking, and year-over-year growth.',
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // STATE A
          // ====================================================

          _StateSelector(
            label: 'State A',
            value: _stateA,
            states: _latestStates,
            icon: Icons.location_on_outlined,
            onChanged: (value) {
              setState(() {
                _stateA = value;
                _showComparison = false;
              });
            },
          ),

          const SizedBox(height: 12),

          // ====================================================
          // COMPARISON ICON
          // ====================================================

          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFB6D5E1),
                ),
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                color: Color(0xFF075985),
                size: 24,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ====================================================
          // STATE B
          // ====================================================

          _StateSelector(
            label: 'State B',
            value: _stateB,
            states: _latestStates,
            icon: Icons.location_on_outlined,
            onChanged: (value) {
              setState(() {
                _stateB = value;
                _showComparison = false;
              });
            },
          ),

          const SizedBox(height: 18),

          // ====================================================
          // COMPARE BUTTON
          // ====================================================

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _compareStates,
              icon: const Icon(
                Icons.compare_arrows_rounded,
              ),
              label: const Text(
                'Compare States',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                backgroundColor:
                const Color(0xFF168AAD),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          // ====================================================
          // COMPARISON RESULT
          // ====================================================

          if (_showComparison &&
              latestA != null &&
              latestB != null) ...[
            const SizedBox(height: 24),

            const Text(
              'Comparison Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ComparisonCard(
                    state: latestA.state,
                    population:
                    _formatPopulation(
                      latestA.population,
                    ),
                    ranking:
                    rankA == 0 ? 'N/A' : '#$rankA',
                    year:
                    latestA.date.year.toString(),
                    growth:
                    _formatGrowth(growthA),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _ComparisonCard(
                    state: latestB.state,
                    population:
                    _formatPopulation(
                      latestB.population,
                    ),
                    ranking:
                    rankB == 0 ? 'N/A' : '#$rankB',
                    year:
                    latestB.date.year.toString(),
                    growth:
                    _formatGrowth(growthB),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ==================================================
            // COMPARISON INSIGHT
            // ==================================================

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FC),
                borderRadius:
                BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFB6D5E1),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF168AAD),
                      ),

                      SizedBox(width: 8),

                      Text(
                        'Comparison Insight',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _buildInsight(
                      latestA,
                      latestB,
                      rankA,
                      rankB,
                    ),
                    style: const TextStyle(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ==================================================
            // SAVE REPORT BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSavingReport
                    ? null
                    : () async {
                  await _saveComparisonReport(
                    stateA: latestA,
                    stateB: latestB,
                    rankA: rankA,
                    rankB: rankB,
                  );
                },
                icon: _isSavingReport
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.bookmark_add_outlined,
                ),
                label: Text(
                  _isSavingReport
                      ? 'Saving...'
                      : 'Save Comparison Report',
                ),
                style: FilledButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  backgroundColor:
                  const Color(0xFF168AAD),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// STATE SELECTOR
// ============================================================

class _StateSelector extends StatelessWidget {
  final String label;
  final String? value;
  final List<StatePopulationData> states;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _StateSelector({
    required this.label,
    required this.value,
    required this.states,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      items: states
          .map(
            (state) => DropdownMenuItem<String>(
          value: state.state,
          child: Text(
            state.state,
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ============================================================
// COMPARISON CARD
// ============================================================

class _ComparisonCard extends StatelessWidget {
  final String state;
  final String population;
  final String ranking;
  final String year;
  final String growth;

  const _ComparisonCard({
    required this.state,
    required this.population,
    required this.ranking,
    required this.year,
    required this.growth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF075985),
            Color(0xFF168AAD),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF075985)
                .withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            state,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _ComparisonValue(
            label: 'Population',
            value: population,
            icon: Icons.people_alt_outlined,
          ),

          _ComparisonValue(
            label: 'Malaysia Rank',
            value: ranking,
            icon: Icons.leaderboard_outlined,
          ),

          _ComparisonValue(
            label: 'Latest Year',
            value: year,
            icon: Icons.calendar_today_outlined,
          ),

          _ComparisonValue(
            label: 'YoY Growth',
            value: growth,
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPARISON VALUE
// ============================================================

class _ComparisonValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ComparisonValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.white70,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}