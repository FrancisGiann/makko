import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MakkoTransitionPage<T> extends CustomTransitionPage<T> {
  MakkoTransitionPage({
    required super.child,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // A smooth fade-up transition (Slide + Fade)
            final tween = Tween(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

// For bottom sheet overlays
class MakkoBottomSheetPage<T> extends CustomTransitionPage<T> {
  MakkoBottomSheetPage({
    required super.child,
    super.key,
  }) : super(
          opaque: false, // Ensure we can see the background
          barrierColor: Colors.black54, // Dimming background
          barrierDismissible: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}
