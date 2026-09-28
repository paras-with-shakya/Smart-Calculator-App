import 'package:flutter/widgets.dart';

/// Animation durations and curves.
///
/// Motion is fast and only confirms what the user did. When the platform
/// asks for reduced motion, [durationOf] returns zero, so the change
/// happens without movement.
abstract final class AppMotion {
  /// 100 ms: press feedback on keys and buttons.
  static const Duration short = Duration(milliseconds: 100);

  /// 200 ms: small transitions, such as a result appearing or the theme
  /// changing.
  static const Duration medium = Duration(milliseconds: 200);

  /// 300 ms: larger movement, such as sheets and layout changes.
  static const Duration long = Duration(milliseconds: 300);

  /// Default curve for things that settle into place.
  static const Curve standard = Curves.easeOutCubic;

  /// Curve for movement that should feel deliberate, such as a sheet.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// [duration], or zero when the platform asks for reduced motion.
  static Duration durationOf(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
