/// Spacing values, in logical pixels.
///
/// Provisional: Phase 2 defines the full spacing scale (docs/ROADMAP.md).
/// Only the steps used so far exist.
abstract final class AppSpacing {
  /// Small gap, such as between a label and its control.
  static const double sm = 8;

  /// Default gap between related elements and default content padding.
  static const double md = 16;

  /// Large gap, such as the padding around a placeholder.
  static const double lg = 24;
}
