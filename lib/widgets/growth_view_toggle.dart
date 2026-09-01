import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GrowthView { yearly, monthly }

class GrowthViewToggle extends StatelessWidget {
  final GrowthView selected;
  final ValueChanged<GrowthView> onChanged;

  const GrowthViewToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _button(context, 'Yearly', GrowthView.yearly)),
        const SizedBox(width: 8),
        Expanded(child: _button(context, 'Monthly', GrowthView.monthly)),
      ],
    );
  }

  Widget _button(BuildContext context, String label, GrowthView value) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}