/// Spacing scale, in logical pixels, on a 4 dp grid.
///
/// Use these for every gap and padding; never write a raw number.
abstract final class AppSpacing {
  /// 4: hairline gaps, such as between an icon and a tight label.
  static const double xs = 4;

  /// 8: between a label and its control, and between grid tiles.
  static const double sm = 8;

  /// 16: default content padding and the gap between related elements.
  static const double md = 16;

  /// 24: between groups, and around sheets, dialogs and empty states.
  static const double lg = 24;

  /// 32: between page sections.
  static const double xl = 32;

  /// 48: large separations, such as above a page's final action.
  static const double xxl = 48;
}
