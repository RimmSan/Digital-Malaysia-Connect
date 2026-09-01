import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_grid_card.dart';
import '../widgets/note_card.dart';
import '../widgets/note_form_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/state_views.dart';
import '../widgets/sparkline_chart.dart';
import '../widgets/state_ranking_sheet.dart';
import '../widgets/dashboard_search_bar.dart';
import '../services/api_service.dart';
import '../services/dashboard_notes_service.dart';
import '../models/domain_data.dart';
import '../models/population_data.dart';
import '../models/internet_penetration_data.dart';
import '../models/state_population_data.dart';
import '../models/dashboard_note.dart';
import '../models/dashboard_preferences.dart';
import '../models/search_result_item.dart';
import '../services/dashboard_preference_service.dart';
import '../widgets/dashboard_customize_sheet.dart';
import '../utils/dashboard_stats.dart';
import 'analytics_page.dart';
import 'growth_page.dart';
import 'intelligence_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  final DashboardNotesService _notesService = DashboardNotesService();
  final DashboardPreferencesService _preferencesService =
  DashboardPreferencesService();

  DashboardPreferences _preferences = DashboardPreferences();

  List<DomainData> _domains = [];
  List<PopulationData> _population = [];
  List<InternetPenetrationData> _internetPenetration = [];
  List<StatePopulationData> _statePopulation = [];
  List<DashboardNote> _notes = [];

  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _refreshedAt;

  // ---- Global search (mirrors the mockup's top search bar) ----
  final TextEditingController _globalSearchController = TextEditingController();
  String _globalSearchQuery = '';
  final GlobalKey _statsGridKey = GlobalKey();
  final GlobalKey _recentUpdatesKey = GlobalKey();

  // ---- My Insights search/filter (separate, scoped to that section) ----
  final TextEditingController _notesSearchController = TextEditingController();
  String _notesSearchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _globalSearchController.addListener(() {
      setState(() {
        _globalSearchQuery = _globalSearchController.text.trim().toLowerCase();
      });
    });
    _notesSearchController.addListener(() {
      setState(() {
        _notesSearchQuery = _notesSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _globalSearchController.dispose();
    _notesSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _apiService.getDomains(),
        _apiService.getPopulation(),
        _apiService.getInternetPenetration(),
        _apiService.getStatePopulation(),
      ]);

      final notes = await _notesService.getAll();
      final preferences = await _preferencesService.get();

      setState(() {
        _domains = results[0] as List<DomainData>;
        _population = results[1] as List<PopulationData>;
        _internetPenetration = results[2] as List<InternetPenetrationData>;
        _statePopulation = results[3] as List<StatePopulationData>;
        _notes = notes;
        _preferences = preferences;
        _isLoading = false;
        _refreshedAt = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data. Pull down or tap '
            'retry to try again.';
      });
    }
  }

  Future<void> _reloadNotesOnly() async {
    final notes = await _notesService.getAll();
    if (mounted) setState(() => _notes = notes);
  }

  // ============================================================
  // PERSONALISED DASHBOARD (Customize)
  // ============================================================

  Future<void> _openCustomizeSheet() async {
    final result = await showCustomizeDashboardSheet(
      context,
      current: _preferences,
    );
    if (result != null) {
      setState(() => _preferences = result);
      await _preferencesService.save(result);
    }
  }

  // ============================================================
  // NOTES CRUD HANDLERS
  // ============================================================

  Future<void> _createNote() async {
    final result = await showNoteFormSheet(context);
    if (result != null) {
      await _notesService.create(result);
      await _reloadNotesOnly();
    }
  }

  Future<void> _editNote(DashboardNote note) async {
    final result = await showNoteFormSheet(context, existingNote: note);
    if (result != null) {
      await _notesService.update(result);
      await _reloadNotesOnly();
    }
  }

  Future<void> _deleteNote(String id) async {
    setState(() => _notes.removeWhere((n) => n.id == id));
    await _notesService.delete(id);
  }

  List<DashboardNote> get _filteredNotes {
    return _notes.where((n) {
      final matchesCategory =
          _selectedCategory == 'All' || n.category == _selectedCategory;
      final matchesSearch = _notesSearchQuery.isEmpty ||
          n.title.toLowerCase().contains(_notesSearchQuery) ||
          n.note.toLowerCase().contains(_notesSearchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // ============================================================
  // GLOBAL SEARCH
  // ============================================================

  void _clearGlobalSearch() {
    _globalSearchController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  List<SearchResultItem> _buildSearchResults({
    required String query,
    required String internetValue,
    required String domainsValue,
    required String populationValue,
    required int score,
    required StatePopulationData? topState,
    required String lastUpdatedLabel,
  }) {
    if (query.isEmpty) return [];
    final results = <SearchResultItem>[];

    // ---- States ----
    for (final s in _statePopulation) {
      if (s.state.toLowerCase().contains(query)) {
        results.add(SearchResultItem(
          title: s.state,
          subtitle: '${DashboardStats.formatCompact(s.population)} people',
          category: 'State',
          icon: Icons.map_outlined,
          color: AppColors.population,
          onTap: () {
            _clearGlobalSearch();
            showStateRankingSheet(
              context,
              states: _statePopulation,
              highlightState: s.state,
            );
          },
        ));
      }
    }

    // ---- Metrics (the stat grid cards) ----
    final metrics = <(String, String, IconData, Color)>[
      ('Internet Penetration', internetValue, Icons.wifi, AppColors.internet),
      ('My Domains', domainsValue, Icons.language, AppColors.domains),
      ('Population', populationValue, Icons.people_alt_outlined, AppColors.population),
      ('Digital Score', '$score/100', Icons.speed, AppColors.primary),
      (
      'Top Digital State',
      topState?.state ?? '--',
      Icons.emoji_events_outlined,
      AppColors.warning,
      ),
      ('Last Updated', lastUpdatedLabel, Icons.update, AppColors.general),
    ];
    for (final m in metrics) {
      if (m.$1.toLowerCase().contains(query)) {
        results.add(SearchResultItem(
          title: m.$1,
          subtitle: 'Current value: ${m.$2}',
          category: 'Metric',
          icon: m.$3,
          color: m.$4,
          onTap: () {
            _clearGlobalSearch();
            _scrollToKey(_statsGridKey);
          },
        ));
      }
    }

    // ---- Datasets ----
    const datasetNames = [
      'Domain Registrations dataset',
      'Population dataset',
      'Internet Penetration dataset',
      'State Population dataset',
    ];
    for (final name in datasetNames) {
      if (name.toLowerCase().contains(query)) {
        results.add(SearchResultItem(
          title: name,
          subtitle: 'Government open dataset',
          category: 'Dataset',
          icon: Icons.dataset_outlined,
          color: AppColors.domains,
          onTap: () {
            _clearGlobalSearch();
            _scrollToKey(_recentUpdatesKey);
          },
        ));
      }
    }

    // ---- My Insights ----
    for (final n in _notes) {
      if (n.title.toLowerCase().contains(query) ||
          n.note.toLowerCase().contains(query)) {
        results.add(SearchResultItem(
          title: n.title,
          subtitle: n.note.isNotEmpty ? n.note : 'My Insight',
          category: 'My Insight',
          icon: Icons.push_pin_outlined,
          color: AppColors.forCategory(n.category),
          onTap: () {
            _clearGlobalSearch();
            _editNote(n);
          },
        ));
      }
    }

    return results.take(20).toList();
  }

  String _relativeTime(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days < 1) return 'Today';
    if (days < 30) return '${days}d ago';
    if (days < 365) return '${(days / 30).floor()}mo ago';
    return '${(days / 365).floor()}yr ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadDashboardData);
    }

    final topState = DashboardStats.topState(_statePopulation);
    final score = DashboardStats.connectivityScore(_internetPenetration);
    final internetTrend =
    DashboardStats.internetPenetrationTrend(_internetPenetration);
    final domainTrend = DashboardStats.domainRegistrationsTrend(_domains);
    final internetValue = DashboardStats.internetPenetration(_internetPenetration);
    final domainsValue = DashboardStats.domainRegistrations(_domains);
    final populationValue = DashboardStats.population(_population);

    final domainsLatest = DashboardStats.latestDate(_domains, (d) => d.date);
    final populationLatest = DashboardStats.latestDate(_population, (d) => d.date);
    final internetLatest =
    DashboardStats.latestDate(_internetPenetration, (d) => d.date);
    final stateLatest = DashboardStats.latestDate(_statePopulation, (d) => d.date);
    final overallLastUpdated = DashboardStats.overallLastUpdated(
      [domainsLatest, populationLatest, internetLatest, stateLatest],
    );
    final lastUpdatedLabel = overallLastUpdated != null
        ? DashboardStats.formatMonthYear(overallLastUpdated)
        : '--';

    final searchResults = _buildSearchResults(
      query: _globalSearchQuery,
      internetValue: internetValue,
      domainsValue: domainsValue,
      populationValue: populationValue,
      score: score,
      topState: topState,
      lastUpdatedLabel: lastUpdatedLabel,
    );

    final filteredNotes = _filteredNotes;

    // ---- Stat grid cards, filtered by personalization preferences ----
    final statCards = <Widget>[
      if (_preferences.showInternetCard)
        StatGridCard(
          label: 'Internet Penetration',
          value: internetValue,
          icon: Icons.wifi,
          color: AppColors.internet,
        ),
      if (_preferences.showDomainsCard)
        StatGridCard(
          label: 'My Domains',
          value: domainsValue,
          icon: Icons.language,
          color: AppColors.domains,
        ),
      if (_preferences.showPopulationCard)
        StatGridCard(
          label: 'Population',
          value: populationValue,
          icon: Icons.people_alt_outlined,
          color: AppColors.population,
        ),
      if (_preferences.showDigitalScoreCard)
        StatGridCard(
          label: 'Digital Score',
          value: '$score/100',
          icon: Icons.speed,
          color: AppColors.primary,
        ),
      if (_preferences.showTopStateCard)
        StatGridCard(
          label: 'Top Digital State',
          value: topState?.state ?? '--',
          icon: Icons.emoji_events_outlined,
          color: AppColors.warning,
          onTap: () => showStateRankingSheet(
            context,
            states: _statePopulation,
            highlightState: topState?.state,
          ),
        ),
      if (_preferences.showLastUpdatedCard)
        StatGridCard(
          label: 'Last Updated',
          value: lastUpdatedLabel,
          icon: Icons.update,
          color: AppColors.general,
          onTap: () => _scrollToKey(_recentUpdatesKey),
        ),
    ];

    final datasetRows = <(String, DateTime?, IconData, Color)>[
      ('Domain Registrations', domainsLatest, Icons.language, AppColors.domains),
      ('Population Data', populationLatest, Icons.people_alt_outlined, AppColors.population),
      ('Internet Penetration', internetLatest, Icons.wifi, AppColors.internet),
      ('State Population', stateLatest, Icons.map_outlined, AppColors.general),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
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
              // ============================================================
              // HERO: Welcome back / Malaysia's Digital Pulse
              // ============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Malaysia's Digital Pulse",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Real-time open data monitoring · '
                                '${DashboardStats.formatMonthYear(DateTime.now())}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.wifi, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ============================================================
              // GLOBAL SEARCH
              // ============================================================
              DashboardSearchBar(
                controller: _globalSearchController,
                results: searchResults,
                isActive: _globalSearchQuery.isNotEmpty,
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ============================================================
              // STAT GRID (personalized via Customize)
              // ============================================================
              SectionTitle(
                title: 'Key Digital Indicators',
                trailing: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.tune, size: 20),
                  tooltip: 'Customize Dashboard',
                  onPressed: _openCustomizeSheet,
                ),
              ),
              const SizedBox(height: 12),

              KeyedSubtree(
                key: _statsGridKey,
                child: statCards.isEmpty
                    ? EmptyStateView(
                  icon: Icons.tune,
                  message: 'All stat cards are hidden. Tap the tune '
                      'icon above to bring them back.',
                )
                    : Column(
                  children: [
                    for (int i = 0; i < statCards.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: statCards[i]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: i + 1 < statCards.length
                                  ? statCards[i + 1]
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sectionGap - 12),

              // ============================================================
              // TRENDS
              // ============================================================
              if (_preferences.showTrends) ...[
                const SectionTitle(
                  title: 'Trends',
                  subtitle: 'How things have moved over the recorded period',
                ),
                const SizedBox(height: 12),

                _TrendCard(
                  title: 'Internet Penetration (Mobile Broadband)',
                  latestLabel: internetTrend.isNotEmpty
                      ? '${internetTrend.last.toStringAsFixed(1)}% latest'
                      : 'No data',
                  values: internetTrend,
                  color: AppColors.internet,
                ),
                const SizedBox(height: 12),

                _TrendCard(
                  title: '.MY Domain Registrations',
                  latestLabel: domainTrend.isNotEmpty
                      ? '${DashboardStats.formatCompact(domainTrend.last)} latest'
                      : 'No data',
                  values: domainTrend,
                  color: AppColors.domains,
                ),

                const SizedBox(height: AppSpacing.sectionGap),
              ],

              // ============================================================
              // RECENT DATASET UPDATES
              // ============================================================
              if (_preferences.showRecentUpdates) ...[
                KeyedSubtree(
                  key: _recentUpdatesKey,
                  child: const SectionTitle(
                    title: 'Recent Dataset Updates',
                    subtitle: 'Latest record date for each source dataset',
                  ),
                ),
                const SizedBox(height: 12),
                ...datasetRows.map((d) {
                  final name = d.$1;
                  final date = d.$2;
                  final icon = d.$3;
                  final color = d.$4;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                date != null
                                    ? 'Latest record: ${DashboardStats.formatMonthYear(date)}'
                                    : 'No data available',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (date != null)
                          Text(
                            _relativeTime(date),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.sectionGap - 10),
              ],

              // ============================================================
              // MY INSIGHTS (CRUD, with its own search + filter)
              // ============================================================
              SectionTitle(
                title: 'My Insights',
                subtitle: 'Pin a stat or jot down what you notice in the '
                    'data. Swipe left to delete, tap the pencil to edit.',
                trailing: TextButton.icon(
                  onPressed: _createNote,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesSearchController,
                decoration: InputDecoration(
                  hintText: 'Search your insights...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _notesSearchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _notesSearchController.clear,
                  )
                      : null,
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', ...DashboardNote.categories].map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.grey.shade100,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              if (filteredNotes.isEmpty)
                EmptyStateView(
                  icon: Icons.push_pin_outlined,
                  message: _notes.isEmpty
                      ? 'No insights yet. Tap "Add" to pin your first one.'
                      : 'No insights match your search/filter.',
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      onEdit: () => _editNote(note),
                      onDelete: () => _deleteNote(note.id),
                    );
                  },
                ),

              const SizedBox(height: AppSpacing.sectionGap - 12),

              // ============================================================
              // QUICK ACTIONS (compact icon row)
              // ============================================================
              const SectionTitle(title: 'Quick Actions'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionIcon(
                      icon: Icons.bar_chart_outlined,
                      label: 'Analytics',
                      color: AppColors.internet,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnalyticsPage()),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _QuickActionIcon(
                      icon: Icons.trending_up,
                      label: 'Growth',
                      color: AppColors.population,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GrowthPage()),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _QuickActionIcon(
                      icon: Icons.public,
                      label: 'Intelligence',
                      color: AppColors.domains,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IntelligencePage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // DATA SOURCE / REFRESH TIME
              // ============================================================
              Center(
                child: Text(
                  'Data source: Malaysian Government Open Data (data.gov.my)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _refreshedAt != null
                      ? 'App data refreshed at '
                      '${_refreshedAt!.hour.toString().padLeft(2, '0')}:'
                      '${_refreshedAt!.minute.toString().padLeft(2, '0')}'
                      ' · Pull down to refresh'
                      : 'App data refreshed: --',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
// TREND CARD (wraps SparklineChart with title + latest value)
// ============================================================

class _TrendCard extends StatelessWidget {
  final String title;
  final String latestLabel;
  final List<double> values;
  final Color color;

  const _TrendCard({
    required this.title,
    required this.latestLabel,
    required this.values,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                latestLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SparklineChart(values: values, color: color),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTION ICON (compact, mockup-style)
// ============================================================

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
