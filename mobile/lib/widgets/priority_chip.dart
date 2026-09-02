import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class PriorityChip extends StatelessWidget {
  final String priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final semantics = context.makkoSemantics;
    final scheme = Theme.of(context).colorScheme;
    Color textColor;

    switch (priority.toLowerCase()) {
      case 'high':
        textColor = semantics.high;
        break;
      case 'medium':
      case 'med':
        textColor = semantics.medium;
        break;
      case 'low':
      default:
        textColor = semantics.low;
        break;
    }

    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: textColor.withAlpha(
        scheme.brightness == Brightness.dark ? 42 : 24,
      ),
      side: BorderSide(color: textColor.withAlpha(90)),
      label: Text(
        priority.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
