/// Material 3 window size classes, chosen by the window's width.
///
/// See https://m3.material.io/foundations/layout/applying-layout/window-size-classes.
enum WindowSizeClass {
  /// Narrower than 600 dp: phones in portrait.
  compact,

  /// 600 dp to 839 dp: tablets in portrait, foldables, small phones in
  /// landscape.
  medium,

  /// 840 dp and wider: tablets in landscape, most phones in landscape,
  /// desktops.
  expanded;

  static const double _mediumMinWidth = 600;
  static const double _expandedMinWidth = 840;

  /// The size class of a window [width] logical pixels wide.
  static WindowSizeClass fromWidth(double width) => switch (width) {
    >= _expandedMinWidth => expanded,
    >= _mediumMinWidth => medium,
    _ => compact,
  };
}
