import 'package:flutter/material.dart';

import '../../models/dashboard_stats.dart';

/// Compact widget designed to be rendered into an image for the Android Companion Home Widget.
class CompanionWidgetRender extends StatelessWidget {
  final DashboardStats? stats;
  final String? greeting;
  final String? customMessage;

  const CompanionWidgetRender({
    super.key,
    this.stats,
    this.greeting,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final openCount = stats?.openIssues ?? 0;
    final message = customMessage ??
        (openCount == 0
            ? 'All clear! Ready to build.'
            : '$openCount active task${openCount == 1 ? '' : 's'} remaining');

    return Container(
      width: 380,
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1527),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF293A4D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shark Avatar with cyan ring and active green dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF164E63).withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/makko-pet.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0C1527),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Info & speech bubble
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'M A K K O',
                          style: TextStyle(
                            color: Color(0xFF22D3EE),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF182742),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              greeting ?? 'On patrol',
                              style: const TextStyle(
                                color: Color(0xFFBBC9CD),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric('Projects', stats?.projectCount ?? 0, const Color(0xFFBBC9CD)),
              _buildStatMetric('All Issues', stats?.totalIssues ?? 0, const Color(0xFFBBC9CD)),
              _buildStatMetric('Open', stats?.openIssues ?? 0, const Color(0xFF22D3EE)),
              _buildStatMetric('Completed', stats?.completedIssues ?? 0, const Color(0xFF34D399)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
