import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/statistic_card.dart';
import '../widgets/note_card.dart';
import '../widgets/note_form_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/state_views.dart';
import '../widgets/sparkline_chart.dart';
import '../services/api_service.dart';
import '../services/dashboard_notes_service.dart';
import '../models/domain_data.dart';
import '../models/population_data.dart';
import '../models/internet_penetration_data.dart';
import '../models/state_population_data.dart';
import '../models/dashboard_note.dart';
import '../models/dashboard_preferences.dart';
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
  DateTime? _lastUpdated;

  // ---- My Insights search/filter state ----
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data. Pull down or tap '
            'retry to try again.';
      });
    }
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

  Future<void> _reloadNotesOnly() async {
    final notes = await _notesService.getAll();
    if (mounted) setState(() => _notes = notes);
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
      final matchesSearch = _searchQuery.isEmpty ||
          n.title.toLowerCase().contains(_searchQuery) ||
          n.note.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
    final filteredNotes = _filteredNotes;

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
              // WELCOME SECTION
              // ============================================================
              const Text(
                'Welcome to Digital Malaysia',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Explore Malaysia\'s digital development through '
                    'government open data.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 22),

              // ============================================================
              // DIGITAL CONNECTIVITY SCORE
              // ============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
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
                            'Digital Connectivity Score',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Malaysia Overview',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 82,
                            height: 82,
                            child: CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '$score%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ============================================================
              // KEY INDICATORS
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

              if (_preferences.showInternetCard) ...[
                StatisticCard(
                  title: 'Internet Penetration',
                  value:
                  DashboardStats.internetPenetration(_internetPenetration),
                  subtitle: 'Mobile broadband · Malaysia',
                  icon: Icons.wifi,
                  iconColor: AppColors.internet,
                ),
                const SizedBox(height: 12),
              ],

              if (_preferences.showDomainsCard) ...[
                StatisticCard(
                  title: '.MY Domain Registration',
                  value: DashboardStats.domainRegistrations(_domains),
                  subtitle: 'Registered domains, latest period',
                  icon: Icons.language,
                  iconColor: AppColors.domains,
                ),
                const SizedBox(height: 12),
              ],

              if (_preferences.showPopulationCard)
                StatisticCard(
                  title: 'Population',
                  value: DashboardStats.population(_population),
                  subtitle: 'Malaysia population, latest period',
                  icon: Icons.people_alt_outlined,
                  iconColor: AppColors.population,
                ),

              if (!_preferences.showInternetCard &&
                  !_preferences.showDomainsCard &&
                  !_preferences.showPopulationCard)
                EmptyStateView(
                  icon: Icons.tune,
                  message: 'All indicator cards are hidden. Tap the tune '
                      'icon above to bring them back.',
                ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ============================================================
              // FEATURE: TRENDS (sparkline charts over time)
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
              // TOP DIGITAL STATE
              // ============================================================
              if (_preferences.showHighlights) ...[
                const SectionTitle(title: 'Digital Highlights'),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'State Population Ranking',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topState?.state ?? '--',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Highest population among Malaysian states',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap),
              ],

              // ============================================================
              // FEATURE 2 + MY INSIGHTS (CRUD): now searchable & filterable
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

              // ---- Search box ----
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search your insights...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchController.clear(),
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

              // ---- Category filter chips ----
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

              const SizedBox(height: 14),

              // ============================================================
              // QUICK ACCESS
              // ============================================================
              const SectionTitle(title: 'Explore More'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      subtitle: 'View trends',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.trending_up,
                      title: 'Growth',
                      subtitle: 'Track growth',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GrowthPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: _QuickActionCard(
                  icon: Icons.map_outlined,
                  title: 'Digital Intelligence',
                  subtitle: 'Explore states, rankings and Malaysia map',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IntelligencePage(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // DATA SOURCE / LAST UPDATED
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
                  _lastUpdated != null
                      ? 'Last updated: ${_formatTime(_lastUpdated!)} · Pull down to refresh'
                      : 'Last updated: --',
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
// QUICK ACTION CARD
// ============================================================

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
