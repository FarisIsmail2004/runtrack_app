import 'package:flutter/widgets.dart';

/// Centralized motion tokens (durations + curves) and reduced-motion handling.
///
/// Every animation in the app pulls its timing from here so durations stay
/// consistent and accessibility (reduced motion) is handled in one place.
class AppMotion {
  AppMotion._();

  // Durations.
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 350);
  static const Duration expressive = Duration(milliseconds: 600);
  static const Duration reveal = Duration(milliseconds: 1200);
  static const Duration breathe = Duration(milliseconds: 1800);

  // Curves.
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve springy = Curves.easeOutBack;

  /// Pure resolver: collapses [base] to [Duration.zero] when motion is reduced.
  static Duration resolve(Duration base, {required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : base;

  /// Whether the platform/user has requested reduced motion.
  static bool reduceMotionOf(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// [base] honoring the ambient reduced-motion setting.
  static Duration duration(BuildContext context, Duration base) =>
      resolve(base, reduceMotion: reduceMotionOf(context));
}
