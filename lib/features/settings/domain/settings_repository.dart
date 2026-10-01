import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
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
}
