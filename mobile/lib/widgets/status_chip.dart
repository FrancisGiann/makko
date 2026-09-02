import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final semantics = context.makkoSemantics;
    final scheme = Theme.of(context).colorScheme;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':
        textColor = semantics.inProgress;
        break;
      case 'done':
        textColor = semantics.done;
        break;
      case 'todo':
      default:
        textColor = semantics.todo;
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
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
