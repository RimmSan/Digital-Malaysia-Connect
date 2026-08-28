import 'package:flutter/material.dart';

import 'malaysia_map_page.dart';
import '../models/state_population_data.dart';
import '../models/intelligence_report.dart';
import '../services/api_service.dart';
import '../services/intelligence_reports_service.dart';
import 'state_comparison_page.dart';
import 'saved_intelligence_reports_page.dart';

class IntelligencePage extends StatefulWidget {
  const IntelligencePage({super.key});

  @override
  State<IntelligencePage> createState() => _IntelligencePageState();
}

class _IntelligencePageState extends State<IntelligencePage> {
  final ApiService _apiService = ApiService();

  final IntelligenceReportsService _reportsService =
  IntelligenceReportsService();

  final ScrollController _scrollController =
  ScrollController();

  bool _isLoading = true;
  String? _errorMessage;

  List<StatePopulationData> _allPopulationData = [];
  List<StatePopulationData> _latestStates = [];

  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _loadStateData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD STATE POPULATION DATA
  // ============================================================

  Future<void> _loadStateData() async {
    try {
      final data =
      await _apiService.getStatePopulation();

      final Map<String, StatePopulationData>
      latestByState = {};

      for (final record in data) {
        final current =
        latestByState[record.state];

        if (current == null ||
            record.date.isAfter(current.date)) {
          latestByState[record.state] =
              record;
        }
      }

      final latestStates =
      latestByState.values.toList()
        ..sort(
              (a, b) =>
              b.population.compareTo(
                a.population,
              ),
        );

      if (!mounted) return;

      setState(() {
        _allPopulationData = data;
        _latestStates = latestStates;

        if (latestStates.isNotEmpty) {
          _selectedState =
              latestStates.first.state;
        }

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

  StatePopulationData? _getLatestRecord(
      String state,
      ) {
    final records =
    _allPopulationData
        .where(
          (record) =>
      record.state == state,
    )
        .toList();

    if (records.isEmpty) {
      return null;
    }

    records.sort(
          (a, b) =>
          b.date.compareTo(a.date),
    );

    return records.first;
  }

  // ============================================================
  // PREVIOUS CALENDAR YEAR
  // ============================================================

  StatePopulationData?
  _getPreviousYearRecord(
      String state,
      StatePopulationData latest,
      ) {
    final previousYear =
        latest.date.year - 1;

    final records =
    _allPopulationData.where(
          (record) =>
      record.state == state &&
          record.date.year ==
              previousYear,
    );

    if (records.isEmpty) {
      return null;
    }

    return records.first;
  }

  // ============================================================
  // STATE RANKING
  // ============================================================

  int _getStateRanking(
      String state,
      ) {
    final index =
    _latestStates.indexWhere(
          (record) =>
      record.state == state,
    );

    if (index == -1) {
      return 0;
    }

    return index + 1;
  }

  // ============================================================
  // FORMAT POPULATION
  // ============================================================

  String _formatPopulation(
      double population,
      ) {
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(2)}M';
    }

    return '${population.toStringAsFixed(1)}K';
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

    return ((latest.population -
        previous.population) /
        previous.population) *
        100;
  }

  // ============================================================
  // SAVE REPORT
  // ============================================================

  Future<void>
  _saveStateInsightReport({
    required String state,
    required String insight,
  }) async {
    final now = DateTime.now();

    final report =
    IntelligenceReport(
      id: now.microsecondsSinceEpoch
          .toString(),
      title: '$state Growth Insight',
      stateA: state,
      stateB: null,
      reportType: 'State Insight',
      insight: insight,
      note: '',
      createdAt: now,
      updatedAt: now,
    );

    await _reportsService.create(
      report,
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$state intelligence report saved successfully.',
        ),
        action: SnackBarAction(
          label: 'VIEW',
          onPressed: () {
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
  }

  // ============================================================
  // SELECT STATE FROM RANKING
  // ============================================================

  void _selectStateFromRanking(
      String state,
      ) {
    setState(() {
      _selectedState = state;
    });

    Future.delayed(
      const Duration(
        milliseconds: 100,
      ),
          () {
        if (_scrollController
            .hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(
              milliseconds: 500,
            ),
            curve:
            Curves.easeInOut,
          );
        }
      },
    );
  }

  // ============================================================
  // SHOW STATE INSIGHT
  // ============================================================

  void _showStateInsight() {
    final state =
        _selectedState;

    if (state == null) {
      return;
    }

    final latest =
    _getLatestRecord(state);

    if (latest == null) {
      return;
    }

    final previous =
    _getPreviousYearRecord(
      state,
      latest,
    );

    final growth =
    _calculateGrowth(
      latest,
      previous,
    );

    final ranking =
    _getStateRanking(state);

    String growthMessage;

    if (growth == null) {
      growthMessage =
      'Population data for ${latest.date.year - 1} is not available, '
          'so year-to-year growth cannot be calculated.';
    } else if (growth > 1) {
      growthMessage =
      '$state recorded noticeable population growth '
          'from ${previous!.date.year} to ${latest.date.year}.';
    } else if (growth > 0) {
      growthMessage =
      '$state recorded moderate population growth '
          'from ${previous!.date.year} to ${latest.date.year}.';
    } else if (growth == 0) {
      growthMessage =
      '$state remained relatively stable '
          'from ${previous!.date.year} to ${latest.date.year}.';
    } else {
      growthMessage =
      '$state recorded a population decrease '
          'from ${previous!.date.year} to ${latest.date.year}.';
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
          const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            32,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                '$state Growth Insight',
                style:
                const TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              _InsightRow(
                label:
                'Latest Population',
                value:
                _formatPopulation(
                  latest.population,
                ),
              ),

              _InsightRow(
                label:
                'Latest Year',
                value:
                latest.date.year
                    .toString(),
              ),

              _InsightRow(
                label:
                'Compared With',
                value:
                previous == null
                    ? '${latest.date.year - 1} unavailable'
                    : previous
                    .date.year
                    .toString(),
              ),

              _InsightRow(
                label:
                'Malaysia Ranking',
                value:
                ranking == 0
                    ? 'N/A'
                    : '#$ranking',
              ),

              _InsightRow(
                label: 'Growth',
                value:
                growth == null
                    ? 'N/A'
                    : '${growth >= 0 ? '+' : ''}'
                    '${growth.toStringAsFixed(2)}%',
              ),

              const SizedBox(
                height: 18,
              ),

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFF1E5A78,
                  ).withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child: Text(
                  growthMessage,
                  style:
                  const TextStyle(
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              SizedBox(
                width:
                double.infinity,
                child:
                FilledButton.icon(
                  onPressed: () async {
                    await _saveStateInsightReport(
                      state: state,
                      insight:
                      growthMessage,
                    );
                  },
                  icon:
                  const Icon(
                    Icons
                        .bookmark_add_outlined,
                  ),
                  label:
                  const Text(
                    'Save Intelligence Report',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'Unable to load intelligence data',
                style:
                TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                _errorMessage!,
                textAlign:
                TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading =
                    true;
                    _errorMessage =
                    null;
                  });

                  _loadStateData();
                },
                child:
                const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
      _loadStateData,
      child: ListView(
        controller:
        _scrollController,
        padding:
        const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          const Text(
            'Malaysia Digital Intelligence',
            style:
            TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Explore, analyse and compare development '
                'indicators across Malaysian states.',
            style:
            TextStyle(
              fontSize: 14,
              height: 1.5,
              color:
              Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          const Text(
            'State Intelligence',
            style:
            TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          DropdownButtonFormField<
              String>(
            initialValue:
            _selectedState,
            decoration:
            InputDecoration(
              labelText:
              'Select State',
              prefixIcon:
              const Icon(
                Icons
                    .location_on_outlined,
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
            ),
            items:
            _latestStates
                .map(
                  (state) =>
                  DropdownMenuItem(
                    value:
                    state.state,
                    child:
                    Text(
                      state.state,
                    ),
                  ),
            )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedState =
                    value;
              });
            },
          ),

          const SizedBox(
            height: 16,
          ),

          if (_selectedState !=
              null)
            _StateOverviewCard(
              state:
              _getLatestRecord(
                _selectedState!,
              )!,
              ranking:
              _getStateRanking(
                _selectedState!,
              ),
              formatPopulation:
              _formatPopulation,
            ),

          const SizedBox(
            height: 14,
          ),

          SizedBox(
            width:
            double.infinity,
            child:
            FilledButton.icon(
              onPressed:
              _showStateInsight,
              icon:
              const Icon(
                Icons.auto_graph,
              ),
              label:
              const Text(
                'Generate State Growth Insight',
              ),
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          const Text(
            'Explore Intelligence',
            style:
            TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child:
                _FeatureCard(
                  icon:
                  Icons.map_outlined,
                  title:
                  'Malaysia Map',
                  subtitle:
                  'Explore states visually',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                        const MalaysiaMapPage(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                _FeatureCard(
                  icon: Icons
                      .compare_arrows_rounded,
                  title:
                  'Compare States',
                  subtitle:
                  'Compare two states',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                        const StateComparisonPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          _FeatureCard(
            icon: Icons
                .bookmark_outline_rounded,
            title:
            'Saved Intelligence Reports',
            subtitle:
            'View your saved reports',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                  const SavedIntelligenceReportsPage(),
                ),
              );
            },
          ),

          const SizedBox(
            height: 30,
          ),

          const Text(
            'Population Ranking',
            style:
            TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Latest available state population data',
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          ..._latestStates
              .take(5)
              .toList()
              .asMap()
              .entries
              .map(
                (entry) {
              final ranking =
                  entry.key + 1;

              final state =
                  entry.value;

              return _RankingTile(
                ranking:
                ranking,
                state:
                state.state,
                population:
                _formatPopulation(
                  state.population,
                ),
                onTap: () {
                  _selectStateFromRanking(
                    state.state,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATE OVERVIEW CARD
// ============================================================

class _StateOverviewCard
    extends StatelessWidget {
  final StatePopulationData state;
  final int ranking;
  final String Function(double)
  formatPopulation;

  const _StateOverviewCard({
    required this.state,
    required this.ranking,
    required this.formatPopulation,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        20,
      ),
      decoration:
      BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(0xFF1E5A78),
            Color(0xFF4D8792),
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            state.state,
            style:
            const TextStyle(
              color:
              Colors.white,
              fontSize: 21,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: [
              Expanded(
                child:
                _OverviewValue(
                  label:
                  'Population',
                  value:
                  formatPopulation(
                    state.population,
                  ),
                ),
              ),

              Expanded(
                child:
                _OverviewValue(
                  label:
                  'Ranking',
                  value:
                  '#$ranking',
                ),
              ),

              Expanded(
                child:
                _OverviewValue(
                  label:
                  'Year',
                  value:
                  state.date.year
                      .toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OVERVIEW VALUE
// ============================================================

class _OverviewValue
    extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style:
          const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          label,
          style:
          const TextStyle(
            color:
            Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FEATURE CARD
// ============================================================

class _FeatureCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surface,
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: Container(
          padding:
          const EdgeInsets.all(
            17,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border:
            Border.all(
              color: Colors.grey
                  .withValues(
                alpha: 0.15,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFF1E5A78,
                  ).withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                  const Color(
                    0xFF1E5A78,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                title,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                subtitle,
                style:
                TextStyle(
                  color: Colors
                      .grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RANKING TILE
// ============================================================

class _RankingTile
    extends StatelessWidget {
  final int ranking;
  final String state;
  final String population;
  final VoidCallback onTap;

  const _RankingTile({
    required this.ranking,
    required this.state,
    required this.population,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      elevation: 0,
      margin:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        onTap: onTap,

        leading:
        CircleAvatar(
          child: Text(
            '$ranking',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        title: Text(
          state,
          style:
          const TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),

        subtitle: Text(
          'Population: $population',
        ),

        trailing:
        const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}

// ============================================================
// INSIGHT ROW
// ============================================================

class _InsightRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _InsightRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
              TextStyle(
                color: Colors
                    .grey.shade600,
              ),
            ),
          ),

          Text(
            value,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}