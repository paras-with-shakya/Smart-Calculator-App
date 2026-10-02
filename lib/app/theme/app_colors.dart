import 'package:flutter/material.dart';

/// The app's colour roles ("quiet precision", DEC-011).
///
/// Warm neutral surfaces ("porcelain" in light mode, "graphite" in dark mode)
/// and one accent, iris, used sparingly: the `=` key, the active mode and the
/// primary action. There is deliberately no separate accent role; [primary]
/// is the accent.
///
/// Read it with `AppColors.of(context)`. Every pair of foreground and
/// background roles is checked against WCAG contrast ratios in
/// `test/app/theme/app_colors_test.dart`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Creates a palette. Use one of the four predefined palettes.
  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.onError,
    required this.divider,
    required this.outline,
    required this.contrastOutline,
    required this.digitKey,
    required this.onDigitKey,
    required this.operatorKey,
    required this.onOperatorKey,
    required this.functionKey,
    required this.onFunctionKey,
    required this.equalsKey,
    required this.onEqualsKey,
  });

  /// Page background.
  final Color background;

  /// Raised surfaces: sheets and dialogs.
  final Color surface;

  /// Cards.
  final Color card;

  /// Quiet fills: text fields, secondary buttons, icon badges.
  final Color surfaceMuted;

  /// Main text and icons.
  final Color textPrimary;

  /// Secondary text: captions, hints, supporting copy.
  final Color textMuted;

  /// The accent (iris): primary actions, the active mode, the `=` key.
  final Color primary;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Accent tint: selected items and active indicators.
  final Color primaryContainer;

  /// Text and icons on [primaryContainer].
  final Color onPrimaryContainer;

  /// Neutral emphasis for secondary icons and controls.
  final Color secondary;

  /// Text and icons on [secondary].
  final Color onSecondary;

  /// Positive feedback text and icons.
  final Color success;

  /// Warning text and icons.
  final Color warning;

  /// Error text and icons, and destructive actions.
  final Color error;

  /// Text and icons on [error].
  final Color onError;

  /// Hairlines between content.
  final Color divider;

  /// Borders of interactive elements, such as a text field.
  final Color outline;

  /// Outline around keys and cards. Transparent except in the high-contrast
  /// palettes, where shapes need a visible edge.
  final Color contrastOutline;

  /// The edge [contrastOutline] draws around a key, card or button: a
  /// hairline in the high-contrast palettes, none otherwise.
  BorderSide get contrastBorder => contrastOutline.a > 0
      ? BorderSide(color: contrastOutline)
      : BorderSide.none;

  /// Digit keys (0-9 and the decimal point): the plain tone.
  final Color digitKey;

  /// Labels on [digitKey].
  final Color onDigitKey;

  /// Operator keys (+ − × ÷): the tinted tone.
  final Color operatorKey;

  /// Operator symbols: the accent colour, on [operatorKey].
  final Color onOperatorKey;

  /// Function keys (AC, brackets, %, backspace): the same tinted tone.
  final Color functionKey;

  /// Function-key labels: the text colour, on [functionKey].
  final Color onFunctionKey;

  /// The `=` key: the only solid-colour key.
  final Color equalsKey;

  /// The label on [equalsKey].
  final Color onEqualsKey;

  /// Light palette: porcelain surfaces.
  static const AppColors light = AppColors(
    background: Color(0xFFF2EFEA),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE7E3DC),
    textPrimary: Color(0xFF1D1B18),
    textMuted: Color(0xFF5E5A53),
    primary: Color(0xFF5652CC),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE5E3FA),
    onPrimaryContainer: Color(0xFF2B2787),
    secondary: Color(0xFF5C564E),
    onSecondary: Color(0xFFFFFFFF),
    success: Color(0xFF1C7249),
    warning: Color(0xFF8F5400),
    error: Color(0xFFB3182A),
    onError: Color(0xFFFFFFFF),
    divider: Color(0xFFDFDAD2),
    outline: Color(0xFF857F76),
    contrastOutline: Color(0x00000000),
    digitKey: Color(0xFFFFFFFF),
    onDigitKey: Color(0xFF1D1B18),
    operatorKey: Color(0xFFE5E3FA),
    onOperatorKey: Color(0xFF4541BD),
    functionKey: Color(0xFFE5E3FA),
    onFunctionKey: Color(0xFF1D1B18),
    equalsKey: Color(0xFF5652CC),
    onEqualsKey: Color(0xFFFFFFFF),
  );

  /// Dark palette: graphite surfaces.
  static const AppColors dark = AppColors(
    background: Color(0xFF141312),
    surface: Color(0xFF1F1E1C),
    // Raised in Phase 11 (was 1F1E1C, about 1.1:1 against the background):
    // with no shadow, a card needs a visible step (about 1.26:1), and a
    // result card should not look dimmer than the fields above it.
    card: Color(0xFF2A2825),
    surfaceMuted: Color(0xFF2B2926),
    textPrimary: Color(0xFFEEEBE6),
    textMuted: Color(0xFFADA79E),
    primary: Color(0xFFA7A3FF),
    onPrimary: Color(0xFF1A1660),
    primaryContainer: Color(0xFF33306A),
    onPrimaryContainer: Color(0xFFE4E2FF),
    secondary: Color(0xFFCBC4B9),
    onSecondary: Color(0xFF2A2723),
    success: Color(0xFF6CCF9A),
    warning: Color(0xFFF0B45B),
    error: Color(0xFFFF9C94),
    onError: Color(0xFF5C0A0E),
    divider: Color(0xFF34322E),
    outline: Color(0xFF8C867D),
    contrastOutline: Color(0x00000000),
    digitKey: Color(0xFF252321),
    onDigitKey: Color(0xFFEEEBE6),
    operatorKey: Color(0xFF2A2846),
    onOperatorKey: Color(0xFFBAB6FF),
    functionKey: Color(0xFF2A2846),
    onFunctionKey: Color(0xFFEEEBE6),
    equalsKey: Color(0xFFA7A3FF),
    onEqualsKey: Color(0xFF1A1660),
  );

  /// High-contrast light palette: near-black text, visible outlines.
  static const AppColors highContrastLight = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE9E5DE),
    textPrimary: Color(0xFF000000),
    textMuted: Color(0xFF33302B),
    primary: Color(0xFF3530A3),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCD9FA),
    onPrimaryContainer: Color(0xFF14105A),
    secondary: Color(0xFF3B362F),
    onSecondary: Color(0xFFFFFFFF),
    success: Color(0xFF0B5230),
    warning: Color(0xFF633900),
    error: Color(0xFF8A0D1B),
    onError: Color(0xFFFFFFFF),
    divider: Color(0xFF6E695F),
    outline: Color(0xFF3B362F),
    contrastOutline: Color(0xFF3B362F),
    digitKey: Color(0xFFF1EEE9),
    onDigitKey: Color(0xFF000000),
    operatorKey: Color(0xFFDCD9FA),
    onOperatorKey: Color(0xFF211C8A),
    functionKey: Color(0xFFDCD9FA),
    onFunctionKey: Color(0xFF000000),
    equalsKey: Color(0xFF3530A3),
    onEqualsKey: Color(0xFFFFFFFF),
  );

  /// High-contrast dark palette: white text on black, visible outlines.
  static const AppColors highContrastDark = AppColors(
    background: Color(0xFF000000),
    surface: Color(0xFF131211),
    card: Color(0xFF131211),
    surfaceMuted: Color(0xFF2A2825),
    textPrimary: Color(0xFFFFFFFF),
    textMuted: Color(0xFFDAD5CD),
    primary: Color(0xFFC9C6FF),
    onPrimary: Color(0xFF0E0B40),
    primaryContainer: Color(0xFF2B2770),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFE4DED4),
    onSecondary: Color(0xFF1A1814),
    success: Color(0xFF8EE6B5),
    warning: Color(0xFFFFCF85),
    error: Color(0xFFFFB3AD),
    onError: Color(0xFF3D0006),
    divider: Color(0xFFA39D93),
    outline: Color(0xFFE4DED4),
    contrastOutline: Color(0xFFE4DED4),
    digitKey: Color(0xFF1C1B19),
    onDigitKey: Color(0xFFFFFFFF),
    operatorKey: Color(0xFF25225C),
    onOperatorKey: Color(0xFFDCDAFF),
    functionKey: Color(0xFF25225C),
    onFunctionKey: Color(0xFFFFFFFF),
    equalsKey: Color(0xFFC9C6FF),
    onEqualsKey: Color(0xFF0E0B40),
  );

  /// The palette of the nearest [Theme].
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? onError,
    Color? divider,
    Color? outline,
    Color? contrastOutline,
    Color? digitKey,
    Color? onDigitKey,
    Color? operatorKey,
    Color? onOperatorKey,
    Color? functionKey,
    Color? onFunctionKey,
    Color? equalsKey,
    Color? onEqualsKey,
  }) => AppColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    card: card ?? this.card,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    textPrimary: textPrimary ?? this.textPrimary,
    textMuted: textMuted ?? this.textMuted,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
    secondary: secondary ?? this.secondary,
    onSecondary: onSecondary ?? this.onSecondary,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    onError: onError ?? this.onError,
    divider: divider ?? this.divider,
    outline: outline ?? this.outline,
    contrastOutline: contrastOutline ?? this.contrastOutline,
    digitKey: digitKey ?? this.digitKey,
    onDigitKey: onDigitKey ?? this.onDigitKey,
    operatorKey: operatorKey ?? this.operatorKey,
    onOperatorKey: onOperatorKey ?? this.onOperatorKey,
    functionKey: functionKey ?? this.functionKey,
    onFunctionKey: onFunctionKey ?? this.onFunctionKey,
    equalsKey: equalsKey ?? this.equalsKey,
    onEqualsKey: onEqualsKey ?? this.onEqualsKey,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      card: mix(card, other.card),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      textPrimary: mix(textPrimary, other.textPrimary),
      textMuted: mix(textMuted, other.textMuted),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primaryContainer: mix(primaryContainer, other.primaryContainer),
      onPrimaryContainer: mix(onPrimaryContainer, other.onPrimaryContainer),
      secondary: mix(secondary, other.secondary),
      onSecondary: mix(onSecondary, other.onSecondary),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      error: mix(error, other.error),
      onError: mix(onError, other.onError),
      divider: mix(divider, other.divider),
      outline: mix(outline, other.outline),
      contrastOutline: mix(contrastOutline, other.contrastOutline),
      digitKey: mix(digitKey, other.digitKey),
      onDigitKey: mix(onDigitKey, other.onDigitKey),
      operatorKey: mix(operatorKey, other.operatorKey),
      onOperatorKey: mix(onOperatorKey, other.onOperatorKey),
      functionKey: mix(functionKey, other.functionKey),
      onFunctionKey: mix(onFunctionKey, other.onFunctionKey),
      equalsKey: mix(equalsKey, other.equalsKey),
      onEqualsKey: mix(onEqualsKey, other.onEqualsKey),
    );
  }
}
