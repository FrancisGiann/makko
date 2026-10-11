import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Keeps GoRouter pages on Flutter's Material route transitions, including
/// Android's predictive-back gesture and the app's PageTransitionsTheme.
class MakkoPage<T> extends MaterialPage<T> {
  const MakkoPage({required super.child, super.key});
}

// For bottom sheet overlays
class MakkoBottomSheetPage<T> extends CustomTransitionPage<T> {
  MakkoBottomSheetPage({required super.child, super.key})
    : super(
        opaque: false, // Ensure we can see the background
        barrierColor: Colors.black54, // Dimming background
        barrierDismissible: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final media = MediaQuery.maybeOf(context);
          final reduceMotion =
              (media?.disableAnimations ?? false) ||
              (media?.accessibleNavigation ?? false);
          if (reduceMotion) {
            return FadeTransition(opacity: animation, child: child);
          }
          final tween = Tween(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 190),
      );
}
