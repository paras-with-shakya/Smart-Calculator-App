import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

/// Reads and saves the user's settings.
abstract interface class SettingsRepository {
  /// The saved theme preference, or [ThemePreference.system] if none is saved.
  ThemePreference get themePreference;

  /// Saves [preference].
  Future<void> setThemePreference(ThemePreference preference);

  /// The saved angle mode, or [AngleMode.degrees] if none is saved.
  AngleMode get angleMode;

  /// Saves [mode].
  Future<void> setAngleMode(AngleMode mode);

  /// The last conversion category used, or null if none is saved yet.
  ConversionCategoryId? get lastConverterCategory;

  /// Saves [category].
  Future<void> setLastConverterCategory(ConversionCategoryId category);

  /// The last from/to unit ids used, for whichever category was last
  /// active, or null if none is saved yet.
  (String from, String to)? get lastConverterUnits;

  /// Saves [from]/[to].
  Future<void> setLastConverterUnits(String from, String to);

  /// The saved "how many of this currency equal 1 USD" rate for
  /// [currencyId], or its starting example rate
  /// (`defaultCurrencyRatesPerUsd`) if none is saved.
  double currencyRate(String currencyId);

  /// Saves [rate] for [currencyId]. [rate] must be positive.
  Future<void> setCurrencyRate(String currencyId, double rate);

  /// The last financial tool selected, or null if none is saved yet.
  FinancialToolId? get lastFinancialTool;

  /// Saves [tool].
  Future<void> setLastFinancialTool(FinancialToolId tool);

  /// Every setting beyond the theme and the angle mode. A value that is
  /// missing, of the wrong type or not recognised is replaced by its
  /// default, so a damaged preferences file can never stop the app.
  AppSettings get appSettings;

  /// Saves the mode the app opens in.
  Future<void> setDefaultMode(CalculatorMode mode);

  /// Saves whether keys give a haptic tick.
  Future<void> setHaptics({required bool enabled});

  /// Saves whether calculator keys make the click sound.
  Future<void> setKeySound({required bool enabled});

  /// Saves how many places results are rounded to.
  Future<void> setDecimalPlaces(DecimalPlaces places);

  /// Saves whether new calculations are added to the history.
  Future<void> setHistoryEnabled({required bool enabled});

  /// Saves how many history entries are kept.
  Future<void> setHistoryLimit(HistoryLimit limit);

  /// Saves the in-app text size.
  Future<void> setTextSize(TextSize size);

  /// Saves whether fixed-height controls are larger.
  Future<void> setLargerControls({required bool enabled});

  /// Saves whether the high-contrast theme is forced.
  Future<void> setHighContrast({required bool enabled});
}
