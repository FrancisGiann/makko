import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Provides a shared 1.8s repeating animation controller for descendant [ShimmerBox]es.
class ShimmerContainer extends StatefulWidget {
  final Widget child;

  const ShimmerContainer({super.key, required this.child});

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    if (reduceMotion) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    return _ShimmerScope(
      controller: _controller,
      disableAnimations: reduceMotion,
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final AnimationController controller;
  final bool disableAnimations;

  const _ShimmerScope({
    required this.controller,
    required this.disableAnimations,
    required super.child,
  });

  static _ShimmerScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();
  }

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) {
    return controller != oldWidget.controller ||
        disableAnimations != oldWidget.disableAnimations;
  }
}

/// A placeholder skeleton box that animates with a sliding gradient band.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const ShimmerBox({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final scope = _ShimmerScope.of(context);
    final disableAnimations =
        scope?.disableAnimations ??
        MediaQuery.maybeOf(context)?.disableAnimations ??
        false;
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(MakkoShapes.radius);

    if (disableAnimations || scope == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: effectiveRadius,
        ),
      );
    }

    final isDark =
        ThemeData.estimateBrightnessForColor(baseColor) == Brightness.dark;
    final highlightColor = isDark
        ? Color.lerp(baseColor, Colors.white, 0.16)!
        : Color.lerp(baseColor, Colors.white, 0.65)!;

    return AnimatedBuilder(
      animation: scope.controller,
      builder: (context, child) {
        final t = scope.controller.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: effectiveRadius,
            gradient: LinearGradient(
              begin: Alignment(-2.5 + 4.5 * t, -0.2),
              end: Alignment(-1.0 + 4.5 * t, 0.2),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
