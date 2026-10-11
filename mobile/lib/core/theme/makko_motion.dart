import 'package:flutter/material.dart';

/// Small shared timing set for motion that explains navigation and state.
/// Flutter's Material controls supply their own interruptible press feedback.
class MakkoMotion {
  static const Duration enter = Duration(milliseconds: 280);
  static const Duration state = Duration(milliseconds: 190);
  static const Duration exit = Duration(milliseconds: 170);

  static bool shouldReduce(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  static AnimationStyle sheetStyle(BuildContext context) {
    if (shouldReduce(context)) return AnimationStyle.noAnimation;
    return const AnimationStyle(duration: enter, reverseDuration: exit);
  }
}
