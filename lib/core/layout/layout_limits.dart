/// Sizes every screen's layout shares, so one number means one thing.
abstract final class LayoutLimits {
  /// The widest a screen's content gets (a keypad, a form, the settings
  /// list), so lines stay readable and keys stay key-sized on a tablet.
  static const double maxContentWidth = 480;

  /// A window shorter than this is compact in height (Material's height
  /// class ends here), such as a phone in landscape.
  static const double compactHeight = 480;
}
