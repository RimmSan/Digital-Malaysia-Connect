import 'package:flutter/material.dart';

import '../models/watchlist_alert.dart';
import '../theme/app_colors.dart';

// ============================================================
// WATCHLIST FORM SHEET
// ------------------------------------------------------------
// Bottom sheet used for both CREATE and UPDATE of a
// WatchlistAlert. Pass `existingAlert` to edit; omit it to
// create a new one. Mirrors the NoteFormSheet pattern already
// used by the Dashboard's "My Insights" CRUD.
// ============================================================

Future<WatchlistAlert?> showWatchlistFormSheet(
    BuildContext context, {
      WatchlistAlert? existingAlert,
    }) {
  return showModalBottomSheet<WatchlistAlert>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _WatchlistFormSheet(existingAlert: existingAlert),
  );
}

class _WatchlistFormSheet extends StatefulWidget {
  final WatchlistAlert? existingAlert;

  const _WatchlistFormSheet({this.existingAlert});

  @override
  State<_WatchlistFormSheet> createState() => _WatchlistFormSheetState();
}

class _WatchlistFormSheetState extends State<_WatchlistFormSheet> {
  late String _metricKey;
  late WatchlistDirection _direction;
  late TextEditingController _thresholdController;

  bool get _isEditing => widget.existingAlert != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlert;
    _metricKey = existing?.metricKey ?? WatchlistAlert.metricKeys.first;
    _direction = existing?.direction ?? WatchlistDirection.above;
    _thresholdController = TextEditingController(
      text: existing != null ? existing.threshold.toString() : '',
    );
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  void _save() {
    final thresholdValue = double.tryParse(_thresholdController.text.trim());
    if (thresholdValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number for the threshold.')),
      );
      return;
    }

    final now = DateTime.now();
    final result = WatchlistAlert(
      id: widget.existingAlert?.id ?? now.microsecondsSinceEpoch.toString(),
      metricKey: _metricKey,
      metricLabel: WatchlistAlert.labelFor(_metricKey),
      threshold: thresholdValue,
      direction: _direction,
      createdAt: widget.existingAlert?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit Watchlist Alert' : 'New Watchlist Alert',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          const Text('Metric', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WatchlistAlert.metricKeys.map((key) {
              final selected = _metricKey == key;
              return ChoiceChip(
                label: Text(WatchlistAlert.labelFor(key)),
                selected: selected,
                onSelected: (_) => setState(() => _metricKey = key),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text('Alert when value is',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Above'),
                  selected: _direction == WatchlistDirection.above,
                  onSelected: (_) =>
                      setState(() => _direction = WatchlistDirection.above),
                  selectedColor: AppColors.success,
                  labelStyle: TextStyle(
                    color: _direction == WatchlistDirection.above
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Below'),
                  selected: _direction == WatchlistDirection.below,
                  onSelected: (_) =>
                      setState(() => _direction = WatchlistDirection.below),
                  selectedColor: AppColors.danger,
                  labelStyle: TextStyle(
                    color: _direction == WatchlistDirection.below
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Threshold value',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. 90',
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save Changes' : 'Add Alert'),
            ),
          ),
        ],
      ),
    );
  }
}