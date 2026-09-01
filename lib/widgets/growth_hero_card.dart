import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GrowthHeroCard extends StatelessWidget {
  final int currentTotal;
  final double yoyGrowthPercent;

  const GrowthHeroCard({
    super.key,
    required this.currentTotal,
    required this.yoyGrowthPercent,
  });

  @override
  Widget build(BuildContext context) {
    final yoyLabel =
        '${yoyGrowthPercent >= 0 ? '+' : ''}${yoyGrowthPercent.toStringAsFixed(1)}% YoY';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('.MY DOMAIN GROWTH',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${(currentTotal / 1000000).toStringAsFixed(2)}M',
                style: const TextStyle(
                    color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      yoyGrowthPercent >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(yoyLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Registered .MY domains',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}