import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class MakkoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const MakkoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MakkoShapes.screenPadding),
    this.borderRadius = MakkoShapes.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
