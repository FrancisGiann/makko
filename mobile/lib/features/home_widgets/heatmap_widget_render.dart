import 'package:flutter/material.dart';

import '../github/github_contribution_graph.dart';

/// Compact widget designed to be rendered into an image for the Android GitHub Heatmap Home Widget.
class HeatmapWidgetRender extends StatelessWidget {
  final String? username;
  final GithubContributionsData? data;

  const HeatmapWidgetRender({
    super.key,
    this.username,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final user = username ?? 'FrancisGiann';
    final contributions = data?.totalContributions ?? 0;

    // Grid: 53 cols x 7 rows
    final grid = List.generate(
      7,
      (_) => List<ContributionDay?>.filled(53, null),
    );

    if (data != null && data!.days.isNotEmpty) {
      for (final day in data!.days) {
        if (day.row != null &&
            day.col != null &&
            day.row! >= 0 &&
            day.row! < 7 &&
            day.col! >= 0 &&
            day.col! < 53) {
          grid[day.row!][day.col!] = day;
        }
      }
    }

    // Show the most recent 24 weeks for a clean, legible home screen widget view
    const displayWeeks = 24;
    const startCol = 53 - displayWeeks;

    return Container(
      width: 380,
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1527),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF293A4D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'G I T H U B',
                      style: TextStyle(
                        color: Color(0xFF22D3EE),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Activity · @$user',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$contributions total',
                style: const TextStyle(
                  color: Color(0xFFBBC9CD),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Mini Heatmap Grid (recent weeks)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(displayWeeks, (i) {
                final colIndex = startCol + i;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    children: List.generate(7, (rowIndex) {
                      final cell = grid[rowIndex][colIndex];
                      final level = cell?.level ?? 0;
                      final color = _getLevelColor(level);

                      return Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent activity',
                style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 10,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Less',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(width: 4),
                  for (var lvl = 0; lvl <= 4; lvl++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: _getLevelColor(lvl),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Text(
                    'More',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _getLevelColor(int level) => switch (level) {
        1 => const Color(0xFF22D3EE).withValues(alpha: 0.3),
        2 => const Color(0xFF22D3EE).withValues(alpha: 0.5),
        3 => const Color(0xFF22D3EE).withValues(alpha: 0.8),
        4 => const Color(0xFF22D3EE),
        _ => const Color(0xFF243653),
      };
}
