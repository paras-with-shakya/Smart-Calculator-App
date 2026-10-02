/// Keys of every value the app keeps in shared preferences.
///
/// [all] is also the preferences cache allow-list: a key missing from it can
/// be neither read nor written.
abstract final class PreferenceKeys {
  /// The theme the user chose: system, light or dark.
  static const String themePreference = 'settings.theme_preference';

  /// Whether trigonometric functions work in degrees or radians.
  static const String angleMode = 'settings.angle_mode';

  /// The calculator memory, as an exact fraction (`CalcValue`'s storage
  /// form). Absent when the memory is empty.
  static const String calculatorMemory = 'calculator.memory';

  /// The last conversion category used.
  static const String converterLastCategory = 'converter.last_category';

  /// The last from-unit id used, for whichever category was last active.
  static const String converterLastFromUnit = 'converter.last_from_unit';

  /// The last to-unit id used, for whichever category was last active.
  static const String converterLastToUnit = 'converter.last_to_unit';

  /// The saved "per 1 USD" rate for the INR currency unit.
  static const String converterCurrencyRateInr = 'converter.currency_rate.inr';

  /// The saved "per 1 USD" rate for the EUR currency unit.
  static const String converterCurrencyRateEur = 'converter.currency_rate.eur';

  /// The saved "per 1 USD" rate for the GBP currency unit.
  static const String converterCurrencyRateGbp = 'converter.currency_rate.gbp';

  /// The last financial tool selected.
  static const String financialLastTool = 'financial.last_tool';

  /// The mode the app opens in.
  static const String defaultMode = 'settings.default_mode';

  /// Whether keys give a haptic tick.
  static const String haptics = 'settings.haptics';

  /// Whether calculator keys make the click sound.
  static const String keySound = 'settings.key_sound';

  /// How many places calculator results are rounded to.
  static const String decimalPlaces = 'settings.decimal_places';

  /// Whether new calculations are added to the history.
  static const String historyEnabled = 'settings.history_enabled';

  /// How many history entries are kept.
  static const String historyLimit = 'settings.history_limit';

  /// The in-app text size.
  static const String textSize = 'settings.text_size';

  /// Whether fixed-height controls are larger.
  static const String largerControls = 'settings.larger_controls';

  /// Whether the high-contrast theme is forced.
  static const String highContrast = 'settings.high_contrast';

  /// Every key above.
  static const Set<String> all = {
    themePreference,
    angleMode,
    calculatorMemory,
    converterLastCategory,
    converterLastFromUnit,
    converterLastToUnit,
    converterCurrencyRateInr,
    converterCurrencyRateEur,
    converterCurrencyRateGbp,
    financialLastTool,
    defaultMode,
    haptics,
    keySound,
    decimalPlaces,
    historyEnabled,
    historyLimit,
    textSize,
    largerControls,
    highContrast,
  };
}
