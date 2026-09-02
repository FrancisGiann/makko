import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class MakkoLogo extends StatelessWidget {
  final bool compact;

  const MakkoLogo({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Makko',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 32 : 38,
            height: compact ? 32 : 38,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(MakkoShapes.radius),
            ),
            child: Icon(
              Icons.waves_rounded,
              color: scheme.onPrimaryContainer,
              size: compact ? 19 : 22,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            Text(
              'makko',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(letterSpacing: -0.5),
            ),
          ],
        ],
      ),
    );
  }
}
