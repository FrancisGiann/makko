import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? actionButton;
  final bool useDashedBorder;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionButton,
    this.useDashedBorder = false,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget body = Padding(
      padding: const EdgeInsets.all(MakkoShapes.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 56, color: scheme.outline),
          const SizedBox(height: MakkoShapes.gutter),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.actionButton != null) ...[
            const SizedBox(height: MakkoShapes.screenPadding),
            widget.actionButton!,
          ],
        ],
      ),
    );

    if (widget.useDashedBorder) {
      body = Container(
        width: double.infinity,
        margin: const EdgeInsets.all(MakkoShapes.screenPadding),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: body,
      );
    }

    final content = Center(child: body);

    if (disableAnimations) {
      return content;
    }

    return FadeTransition(
      opacity: _fade,
      child: content,
    );
  }
}
