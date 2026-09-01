import 'package:flutter/material.dart';
import '../models/dashboard_preferences.dart';
import '../theme/app_colors.dart';

// ============================================================
// CUSTOMIZE DASHBOARD SHEET
// ------------------------------------------------------------
// Lets the user show/hide dashboard sections. Returns the updated
// DashboardPreferences via Navigator.pop when saved, or null if
// dismissed without saving.
// ============================================================

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
              'Choose which sections appear on your dashboard.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Internet Penetration card'),
              value: _prefs.showInternetCard,
              onChanged: (v) => setState(
                    () => _prefs = _prefs.copyWith(showInternetCard: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('.MY Domain Registration card'),
              value: _prefs.showDomainsCard,
              onChanged: (v) => setState(
                    () => _prefs = _prefs.copyWith(showDomainsCard: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Population card'),
              value: _prefs.showPopulationCard,
              onChanged: (v) => setState(
                    () => _prefs = _prefs.copyWith(showPopulationCard: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Trends section'),
              value: _prefs.showTrends,
              onChanged: (v) => setState(
                    () => _prefs = _prefs.copyWith(showTrends: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Digital Highlights section'),
              value: _prefs.showHighlights,
              onChanged: (v) => setState(
                    () => _prefs = _prefs.copyWith(showHighlights: v),
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
