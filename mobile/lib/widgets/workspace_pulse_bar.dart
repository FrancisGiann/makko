import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A 12-segment horizontal progress bar representing workspace issue completion.
class WorkspacePulseBar extends StatelessWidget {
  final int completed;
  final int total;

  const WorkspacePulseBar({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeTotal = math.max(0, total);
    final safeCompleted = math.max(0, math.min(completed, safeTotal));
    final percent = safeTotal > 0
        ? ((safeCompleted / safeTotal) * 100).round()
        : 0;

    final rawSegments = (percent / 100 * 12).round();
    final filledSegments = safeTotal == 0
        ? 0
        : (safeCompleted == safeTotal
            ? 12
            : (safeCompleted > 0 ? rawSegments.clamp(1, 11) : 0));

    final countLabel = safeTotal > 0
        ? '$safeCompleted of $safeTotal internal ${safeTotal == 1 ? 'issue' : 'issues'} complete'
        : '0 of 0 internal issues complete';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(12, (index) {
            final isFilled = index < filledSegments;
            return Expanded(
              child: Container(
                height: 8,
                margin: EdgeInsets.only(right: index < 11 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isFilled
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(MakkoShapes.radiusFull),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                countLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
