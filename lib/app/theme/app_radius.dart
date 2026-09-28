import 'package:flutter/painting.dart';

/// Corner radii and the app's shape language.
///
/// Every rounded shape is a superellipse ("squircle"), which gives the app
/// its recognisable, softer corners (DEC-011). Build shapes with [shape]
/// rather than `RoundedRectangleBorder`.
abstract final class AppRadius {
  /// 8: small elements, such as chips and badges.
  static const double sm = 8;

  /// 12: buttons and text fields.
  static const double md = 12;

  /// 16: cards and tiles.
  static const double lg = 16;

  /// 24: calculator keys, sheets and dialogs.
  static const double xl = 24;

  /// A superellipse with [radius] on every corner, and an optional [side].
  static RoundedSuperellipseBorder shape(
    double radius, {
    BorderSide side = BorderSide.none,
  }) => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    side: side,
  );
}
