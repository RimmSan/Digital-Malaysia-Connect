import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_title.dart';
import '../widgets/state_views.dart';
import '../widgets/statistic_card.dart';
import '../services/api_service.dart';

// ============================================================
// MODULE TEMPLATE
// ------------------------------------------------------------
// HOW TO USE THIS FILE (read me first):
//
// 1. Copy this file into lib/screens/ and rename it, e.g.
//    "analytics_page.dart".
// 2. Rename the class below from "ModuleTemplatePage" to match
//    your screen, e.g. "AnalyticsPage".
// 3. This screen does NOT have its own AppBar/Scaffold - it's
//    dropped straight into the body of MainNavigation's
//    IndexedStack in main.dart, which already provides the
//    AppBar and bottom nav. Don't wrap this in Scaffold().
// 4. Replace the TODOs below with your module's real data
//    fetching + UI. Keep using SectionTitle / LoadingView /
//    ErrorView / EmptyStateView / StatisticCard / AppColors so
//    every module looks consistent with the Dashboard.
// 5. Delete this comment block once you're done.
// ============================================================

class ModuleTemplatePage extends StatefulWidget {
  const ModuleTemplatePage({super.key});

  @override
  State<ModuleTemplatePage> createState() => _ModuleTemplatePageState();
}

class _ModuleTemplatePageState extends State<ModuleTemplatePage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  // TODO: replace with your module's actual data fields.
  List<dynamic> _data = [];

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

      // TODO: call the real ApiService method(s) your module needs,
      // e.g. await _apiService.getDomains();
      final result = await Future<List<dynamic>>.delayed(
        const Duration(milliseconds: 300),
            () => [],
      );

      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Pull down or tap retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadData);
    }

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
              // ---- Page intro (optional, mirrors Dashboard's welcome text) ----
              const Text(
                'Module Title',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'One-line description of what this module shows.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ---- Example section using shared widgets ----
              const SectionTitle(title: 'Key Figures'),
              const SizedBox(height: 12),

              if (_data.isEmpty)
                const EmptyStateView(
                  icon: Icons.bar_chart_outlined,
                  message: 'No data to show yet.',
                )
              else
              // TODO: replace with real StatisticCard(s) built from _data.
                const StatisticCard(
                  title: 'Example Stat',
                  value: '--',
                  subtitle: 'Replace with real data',
                  icon: Icons.insights_outlined,
                  iconColor: AppColors.primary,
                ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ---- Add more SectionTitle + content blocks as needed ----
            ],
          ),
        ),
      ),
    );
  }
}
