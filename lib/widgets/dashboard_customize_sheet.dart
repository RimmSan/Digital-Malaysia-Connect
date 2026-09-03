import 'package:flutter/material.dart';
import '../models/dashboard_preferences.dart';
import '../theme/app_colors.dart';


Future<DashboardPreferences?> showCustomizeDashboardSheet(
    BuildContext context, {
      required DashboardPreferences current,
    }) {
  return showModalBottomSheet<DashboardPreferences>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CustomizeSheet(current: current),
  );
}

class _CustomizeSheet extends StatefulWidget {
  final DashboardPreferences current;

  const _CustomizeSheet({required this.current});

  @override
  State<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends State<_CustomizeSheet> {
  late DashboardPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = widget.current.copyWith();
  }

  Widget _toggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text(
              'Customize Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose which cards and sections appear.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 2),
                      child: Text(
                        'STAT CARDS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    _toggle(
                      label: 'Internet Penetration',
                      value: _prefs.showInternetCard,
                      onChanged: (v) => setState(
                            () => _prefs = _prefs.copyWith(showInternetCard: v),
                      ),
                    ),
                    _toggle(
                      label: 'My Domains',
                      value: _prefs.showDomainsCard,
                      onChanged: (v) => setState(
                            () => _prefs = _prefs.copyWith(showDomainsCard: v),
                      ),
                    ),
                    _toggle(
                      label: 'Population',
                      value: _prefs.showPopulationCard,
                      onChanged: (v) => setState(
                            () => _prefs = _prefs.copyWith(showPopulationCard: v),
                      ),
                    ),
                    _toggle(
                      label: 'Digital Score',
                      value: _prefs.showDigitalScoreCard,
                      onChanged: (v) => setState(
                            () => _prefs = _prefs.copyWith(showDigitalScoreCard: v),
                      ),
                    ),
                    _toggle(
                      label: 'Top Digital State',
                      value: _prefs.showTopStateCard,
                      onChanged: (v) => setState(
                            () => _prefs = _prefs.copyWith(showTopStateCard: v),
                      ),
                    ),
                    _toggle(
                      label: 'Last Updated',
                      value: _prefs.showLastUpdatedCard,
                      onChanged: (v) => setState(
                            () => _prefs = _prefs.copyWith(showLastUpdatedCard: v),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 2),
                      child: Text(
                        'SECTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    _toggle(
                      label: 'Trends',
                      value: _prefs.showTrends,
                      onChanged: (v) => setState(
                            () => _prefs = _prefs.copyWith(showTrends: v),
                      ),
                    ),
                    _toggle(
                      label: 'Recent Dataset Updates',
                      value: _prefs.showRecentUpdates,
                      onChanged: (v) => setState(
                            () => _prefs = _prefs.copyWith(showRecentUpdates: v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _prefs),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
