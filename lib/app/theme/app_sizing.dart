import 'package:flutter/material.dart';

/// How big the app's fixed-height controls are: 1 normally, 1.25 when
/// "Larger controls" is on in Settings.
///
/// Controls that fill the space they are given (the Basic and Scientific key
/// grids) are unaffected: their keys are already as large as the screen
/// allows. Controls with a set height (buttons, icon buttons, segmented
/// choices, the Converter and Programmer key rows, the memory and
/// scientific rows) read [of] and grow with it.
///
/// This is an [InheritedWidget] rather than a theme extension because the
/// themes are built once, as constants, with their button sizes in them.
/// With no [AppSizing] above (the gallery, most widget tests) the scale is 1.
class AppSizing extends InheritedWidget {
  /// Sets the control scale for everything below.
  const AppSizing({
    super.key,
    required this.controlScale,
    required super.child,
  });

  /// The scale "Larger controls" applies.
  static const double largerControlScale = 1.25;

  /// The size of fixed-height controls relative to normal.
  final double controlScale;

  /// The control scale in effect at [context] (1 if there is none).
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSizing>()?.controlScale ??
      1;

  /// The smallest touch target at [context]: the Material 48 dp, scaled.
  static double minTarget(BuildContext context) =>
      kMinInteractiveDimension * of(context);

  @override
  bool updateShouldNotify(AppSizing oldWidget) =>
      oldWidget.controlScale != controlScale;
}
