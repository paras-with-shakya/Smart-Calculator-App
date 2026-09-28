import 'package:flutter/material.dart';

/// The app's light and dark themes.
///
/// Phase 1 foundation: both themes derive from one seed colour. Phase 2
/// replaces this with the design-system tokens (colour roles, typography,
/// spacing, radius, motion).
abstract final class AppTheme {
  /// Provisional "iris" accent from the approved "quiet precision" direction
  /// (DEC-011). Phase 2 sets the final value.
  static const Color _seedColor = Color(0xFF5B57D1);

  /// Theme used when the app is light.
  static final ThemeData light = _build(Brightness.light);

  /// Theme used when the app is dark.
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
  );
}
