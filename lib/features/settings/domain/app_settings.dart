import 'package:smart_calculator/app/modes/calculator_mode.dart';

/// How many places after the point a calculator result is rounded to.
///
/// Only the fraction is ever rounded, so a whole number is unchanged, and
/// [auto] keeps today's behaviour (up to 12 significant digits).
enum DecimalPlaces {
  /// No extra rounding: up to 12 significant digits.
  auto(null),

  /// Two places.
  two(2),

  /// Four places.
  four(4),

  /// Six places.
  six(6),

  /// Eight places.
  eight(8);

  const DecimalPlaces(this.places);

  /// The number of places, or null for [auto].
  final int? places;
}

/// How many calculations the history keeps.
enum HistoryLimit {
  /// The newest 50.
  fifty(50),

  /// The newest 100.
  hundred(100),

  /// The newest 500.
  fiveHundred(500),

  /// Everything.
  unlimited(null);

  const HistoryLimit(this.keep);

  /// How many of the newest entries are kept, or null for all of them.
  final int? keep;
}

/// A text size chosen in the app, applied on top of the system's.
enum TextSize {
  /// The system's size, unchanged.
  normal(1),

  /// 15% larger than the system's.
  large(1.15),

  /// 30% larger than the system's.
  larger(1.3);

  const TextSize(this.multiplier);

  /// What the system's text scale is multiplied by.
  final double multiplier;
}

/// Every setting that is not the theme or the angle mode (those have their
/// own providers).
///
/// The defaults are the app's behaviour before Phase 10, so a fresh install,
/// or a value that cannot be read back, behaves exactly as it always did.
final class AppSettings {
  /// Creates settings; omitted values are the defaults.
  const AppSettings({
    this.defaultMode = CalculatorMode.basic,
    this.haptics = true,
    this.keySound = true,
    this.decimalPlaces = DecimalPlaces.auto,
    this.historyEnabled = true,
    this.historyLimit = HistoryLimit.unlimited,
    this.textSize = TextSize.normal,
    this.largerControls = false,
    this.highContrast = false,
  });

  /// The mode the app opens in.
  final CalculatorMode defaultMode;

  /// Whether pressing a key gives a haptic tick.
  final bool haptics;

  /// Whether calculator keys make the system click sound (which still
  /// follows the device's touch-sounds setting).
  final bool keySound;

  /// How many places results are rounded to in Basic and Scientific.
  final DecimalPlaces decimalPlaces;

  /// Whether new calculations are added to the history.
  final bool historyEnabled;

  /// How many history entries are kept.
  final HistoryLimit historyLimit;

  /// The in-app text size.
  final TextSize textSize;

  /// Whether fixed-height controls are 25% larger.
  final bool largerControls;

  /// Whether the high-contrast theme is used even if the device does not
  /// ask for it.
  final bool highContrast;

  /// These settings with the given values replaced.
  AppSettings copyWith({
    CalculatorMode? defaultMode,
    bool? haptics,
    bool? keySound,
    DecimalPlaces? decimalPlaces,
    bool? historyEnabled,
    HistoryLimit? historyLimit,
    TextSize? textSize,
    bool? largerControls,
    bool? highContrast,
  }) => AppSettings(
    defaultMode: defaultMode ?? this.defaultMode,
    haptics: haptics ?? this.haptics,
    keySound: keySound ?? this.keySound,
    decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    historyEnabled: historyEnabled ?? this.historyEnabled,
    historyLimit: historyLimit ?? this.historyLimit,
    textSize: textSize ?? this.textSize,
    largerControls: largerControls ?? this.largerControls,
    highContrast: highContrast ?? this.highContrast,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.defaultMode == defaultMode &&
      other.haptics == haptics &&
      other.keySound == keySound &&
      other.decimalPlaces == decimalPlaces &&
      other.historyEnabled == historyEnabled &&
      other.historyLimit == historyLimit &&
      other.textSize == textSize &&
      other.largerControls == largerControls &&
      other.highContrast == highContrast;

  @override
  int get hashCode => Object.hash(
    defaultMode,
    haptics,
    keySound,
    decimalPlaces,
    historyEnabled,
    historyLimit,
    textSize,
    largerControls,
    highContrast,
  );
}
