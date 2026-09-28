import 'package:flutter/material.dart';

/// The app's text styles.
///
/// Every style uses the bundled Manrope font (never downloaded at runtime).
/// Styles that show numbers turn on Manrope's tabular figures, so digits keep
/// the same width and a number doesn't shift while it is typed. Manrope's
/// default figures are proportional.
///
/// Styles carry no colour; widgets apply a colour role from `AppColors`.
/// Read them with `AppTypography.of(context)`.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  /// Creates a type scale. Use [standard].
  const AppTypography({
    required this.display,
    required this.result,
    required this.expression,
    required this.key,
    required this.keySymbol,
    required this.heading,
    required this.title,
    required this.body,
    required this.caption,
    required this.button,
    required this.label,
  });

  /// The bundled font family, declared in pubspec.yaml.
  static const String fontFamily = 'Manrope';

  static const List<FontFeature> _tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// The app's type scale.
  static const AppTypography standard = AppTypography(
    display: TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFeatures: _tabularFigures,
    ),
    result: TextStyle(
      fontFamily: fontFamily,
      fontSize: 48,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      fontFeatures: _tabularFigures,
    ),
    expression: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      height: 1.33,
      fontWeight: FontWeight.w400,
      fontFeatures: _tabularFigures,
    ),
    key: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w500,
      fontFeatures: _tabularFigures,
    ),
    keySymbol: TextStyle(
      fontFamily: fontFamily,
      fontSize: 34,
      height: 1,
      fontWeight: FontWeight.w600,
    ),
    heading: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      height: 1.27,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    title: TextStyle(
      fontFamily: fontFamily,
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    body: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    caption: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    button: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    label: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );

  /// Large numbers outside the calculator, such as a loan's monthly payment.
  final TextStyle display;

  /// The calculator's result.
  final TextStyle result;

  /// The expression being typed, and the live preview.
  final TextStyle expression;

  /// Labels of digit and function keys.
  final TextStyle key;

  /// Operator and `=` symbols, larger and heavier than [key]: Manrope draws
  /// + − × ÷ = small, so at the digits' size they look faint.
  final TextStyle keySymbol;

  /// Page and sheet titles.
  final TextStyle heading;

  /// Titles inside content: cards, list items, empty states.
  final TextStyle title;

  /// Running text.
  final TextStyle body;

  /// Small supporting text.
  final TextStyle caption;

  /// Button labels.
  final TextStyle button;

  /// Section headers, chips and navigation labels.
  final TextStyle label;

  /// The type scale of the nearest [Theme].
  static AppTypography of(BuildContext context) =>
      Theme.of(context).extension<AppTypography>()!;

  @override
  AppTypography copyWith({
    TextStyle? display,
    TextStyle? result,
    TextStyle? expression,
    TextStyle? key,
    TextStyle? keySymbol,
    TextStyle? heading,
    TextStyle? title,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? button,
    TextStyle? label,
  }) => AppTypography(
    display: display ?? this.display,
    result: result ?? this.result,
    expression: expression ?? this.expression,
    key: key ?? this.key,
    keySymbol: keySymbol ?? this.keySymbol,
    heading: heading ?? this.heading,
    title: title ?? this.title,
    body: body ?? this.body,
    caption: caption ?? this.caption,
    button: button ?? this.button,
    label: label ?? this.label,
  );

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTypography(
      display: mix(display, other.display),
      result: mix(result, other.result),
      expression: mix(expression, other.expression),
      key: mix(key, other.key),
      keySymbol: mix(keySymbol, other.keySymbol),
      heading: mix(heading, other.heading),
      title: mix(title, other.title),
      body: mix(body, other.body),
      caption: mix(caption, other.caption),
      button: mix(button, other.button),
      label: mix(label, other.label),
    );
  }
}
