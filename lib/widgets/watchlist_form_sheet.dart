import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/watchlist_alert.dart';
import '../theme/app_colors.dart';


Future<WatchlistAlert?> showWatchlistFormSheet(
    BuildContext context, {
      WatchlistAlert? existingAlert,
      List<WatchlistAlert> existingAlerts = const [],
    }) {
  return showModalBottomSheet<WatchlistAlert>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _WatchlistFormSheet(
      existingAlert: existingAlert,
      existingAlerts: existingAlerts,
    ),
  );
}

class _WatchlistFormSheet extends StatefulWidget {
  final WatchlistAlert? existingAlert;
  final List<WatchlistAlert> existingAlerts;

  const _WatchlistFormSheet({
    this.existingAlert,
    this.existingAlerts = const [],
  });

  @override
  State<_WatchlistFormSheet> createState() => _WatchlistFormSheetState();
}

class _WatchlistFormSheetState extends State<_WatchlistFormSheet> {
  static const int _minThreshold = 0;
  static const int _maxThreshold = 999;

  late String _metricKey;
  late WatchlistDirection _direction;
  late TextEditingController _thresholdController;
  String? _errorText;

  bool get _isEditing => widget.existingAlert != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlert;
    _metricKey = existing?.metricKey ?? WatchlistAlert.metricKeys.first;
    _direction = existing?.direction ?? WatchlistDirection.above;
    _thresholdController = TextEditingController(
      text: existing != null ? existing.threshold.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  String? _validateThreshold(String rawInput) {
    final trimmed = rawInput.trim();

    if (trimmed.isEmpty) {
      return 'Enter a threshold value.';
    }

    final intValue = int.tryParse(trimmed);
    if (intValue == null) {
      return 'Whole numbers only (no decimals or symbols).';
    }

    if (intValue < _minThreshold) {
      return 'Threshold cannot be negative.';
    }

    if (intValue > _maxThreshold) {
      return 'Threshold cannot be more than $_maxThreshold.';
    }

    return null;
  }

  bool _isDuplicate(int thresholdValue) {
    return widget.existingAlerts.any((a) {
      final isSameEntity = _isEditing && a.id == widget.existingAlert!.id;
      if (isSameEntity) return false;
      return a.metricKey == _metricKey && a.direction == _direction;
    });
  }

  void _save() {
    final rawInput = _thresholdController.text;
    final error = _validateThreshold(rawInput);

    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    final intValue = int.parse(rawInput.trim());

    if (_isDuplicate(intValue)) {
      setState(() {
        _errorText =
        'You already have a ${_direction.name} alert for ${WatchlistAlert.labelFor(_metricKey)}.';
      });
      return;
    }

    setState(() => _errorText = null);

    final now = DateTime.now();
    final result = WatchlistAlert(
      id: widget.existingAlert?.id ?? now.microsecondsSinceEpoch.toString(),
      metricKey: _metricKey,
      metricLabel: WatchlistAlert.labelFor(_metricKey),
      threshold: intValue.toDouble(),
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
                onSelected: (_) => setState(() {
                  _metricKey = key;
                  _errorText = null;
                }),
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
                  onSelected: (_) => setState(() {
                    _direction = WatchlistDirection.above;
                    _errorText = null;
                  }),
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
                  onSelected: (_) => setState(() {
                    _direction = WatchlistDirection.below;
                    _errorText = null;
                  }),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Threshold value',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '0 - $_maxThreshold',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _thresholdController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            decoration: InputDecoration(
              hintText: 'e.g. 90',
              isDense: true,
              errorText: _errorText,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.danger),
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