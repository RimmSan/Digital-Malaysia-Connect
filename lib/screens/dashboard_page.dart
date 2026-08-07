import 'package:flutter/material.dart';
import '../widgets/statistic_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ============================================================
            // WELCOME SECTION
            // ============================================================

            const Text(
              'Welcome to Digital Malaysia',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E5A78),
                    Color(0xFF4D8792),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [

                  // Score
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        Text(
                          'Digital Connectivity Score',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          '87',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Malaysia Overview',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Circular score
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
                            value: 0.87,
                            strokeWidth: 8,
                            backgroundColor: Colors.white24,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),

                        const Text(
                          '87%',
                          style: TextStyle(
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

            const SizedBox(height: 26),

            // ============================================================
            // KEY INDICATORS
            // ============================================================

            const Text(
              'Key Digital Indicators',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const StatisticCard(
              title: 'Internet Penetration',
              value: '95.4%',
              subtitle: 'Malaysia',
              icon: Icons.wifi,
              iconColor: Color(0xFF1E5A78),
            ),

            const SizedBox(height: 12),

            const StatisticCard(
              title: '.MY Domain Registration',
              value: '1.82M',
              subtitle: 'Registered domains',
              icon: Icons.language,
              iconColor: Color(0xFF4D6FA3),
            ),

            const SizedBox(height: 12),

            const StatisticCard(
              title: 'Population',
              value: '34.2M',
              subtitle: 'Malaysia population',
              icon: Icons.people_alt_outlined,
              iconColor: Color(0xFF4D8792),
            ),

            const SizedBox(height: 26),

            // ============================================================
            // TOP DIGITAL STATE
            // ============================================================

            const Text(
              'Digital Highlights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [

                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E5A78)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Color(0xFF1E5A78),
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          'Top Digital State',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Selangor',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          'Based on current digital indicators',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // ============================================================
            // QUICK ACCESS
            // ============================================================

            const Text(
              'Explore More',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.analytics_outlined,
                    title: 'Analytics',
                    subtitle: 'View trends',
                    onTap: () {
                      // Navigation will be connected later.
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
                      // Navigation will be connected later.
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
                  // Navigation will be connected later.
                },
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // DATA SOURCE / LAST UPDATED
            // ============================================================

            Center(
              child: Text(
                'Data source: Malaysian Government Open Data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Center(
              child: Text(
                'Last updated: Sample data',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5A78)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1E5A78),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}