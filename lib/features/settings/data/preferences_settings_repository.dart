import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/converter/domain/conversion_tables.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
import 'package:smart_calculator/features/settings/domain/settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

/// The app's [SettingsRepository], backed by the preloaded preferences.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (ref) =>
          PreferencesSettingsRepository(ref.watch(sharedPreferencesProvider)),
    );

/// Stores settings in [SharedPreferencesWithCache].
///
/// Values are stored as fixed strings rather than enum names, so renaming an
/// enum value never invalidates what users have already saved.
final class PreferencesSettingsRepository implements SettingsRepository {
  /// Creates a repository that reads and writes [_preferences].
  const PreferencesSettingsRepository(this._preferences);

  final SharedPreferencesWithCache _preferences;

  @override
  ThemePreference get themePreference {
    final stored = _preferences.getString(PreferenceKeys.themePreference);
    return ThemePreference.values.firstWhere(
      (preference) => _storedValue(preference) == stored,
      orElse: () => ThemePreference.system,
    );
  }

  @override
  Future<void> setThemePreference(ThemePreference preference) => _preferences
      .setString(PreferenceKeys.themePreference, _storedValue(preference));

  @override
  AngleMode get angleMode =>
      _preferences.getString(PreferenceKeys.angleMode) == 'radians'
      ? AngleMode.radians
      : AngleMode.degrees;

  @override
  Future<void> setAngleMode(AngleMode mode) =>
      _preferences.setString(PreferenceKeys.angleMode, switch (mode) {
        AngleMode.degrees => 'degrees',
        AngleMode.radians => 'radians',
      });

  @override
  ConversionCategoryId? get lastConverterCategory {
    final stored = _preferences.getString(PreferenceKeys.converterLastCategory);
    for (final category in ConversionCategoryId.values) {
      if (_categoryStoredValue(category) == stored) return category;
    }
    return null;
  }

  @override
  Future<void> setLastConverterCategory(ConversionCategoryId category) =>
      _preferences.setString(
        PreferenceKeys.converterLastCategory,
        _categoryStoredValue(category),
      );

  @override
  (String from, String to)? get lastConverterUnits {
    final from = _preferences.getString(PreferenceKeys.converterLastFromUnit);
    final to = _preferences.getString(PreferenceKeys.converterLastToUnit);
    return from == null || to == null ? null : (from, to);
  }

  @override
  Future<void> setLastConverterUnits(String from, String to) => Future.wait([
    _preferences.setString(PreferenceKeys.converterLastFromUnit, from),
    _preferences.setString(PreferenceKeys.converterLastToUnit, to),
  ]);

  @override
  double currencyRate(String currencyId) {
    final key = _currencyRateKey(currencyId);
    final stored = key == null ? null : _preferences.getString(key);
    return stored == null
        ? defaultCurrencyRatesPerUsd[currencyId]!
        : double.parse(stored);
  }

  @override
  Future<void> setCurrencyRate(String currencyId, double rate) {
    final key = _currencyRateKey(currencyId);
    if (key == null) return Future.value();
    return _preferences.setString(key, '$rate');
  }

  /// The fixed storage key for [currencyId]'s rate, or null for `usd`
  /// (always fixed at 1, never stored) or an id this app doesn't offer.
  static String? _currencyRateKey(String currencyId) => switch (currencyId) {
    'inr' => PreferenceKeys.converterCurrencyRateInr,
    'eur' => PreferenceKeys.converterCurrencyRateEur,
    'gbp' => PreferenceKeys.converterCurrencyRateGbp,
    _ => null,
  };

  static String _categoryStoredValue(ConversionCategoryId category) =>
      switch (category) {
        ConversionCategoryId.length => 'length',
        ConversionCategoryId.weight => 'weight',
        ConversionCategoryId.temperature => 'temperature',
        ConversionCategoryId.area => 'area',
        ConversionCategoryId.volume => 'volume',
        ConversionCategoryId.time => 'time',
        ConversionCategoryId.currency => 'currency',
      };

  @override
  FinancialToolId? get lastFinancialTool {
    final stored = _preferences.getString(PreferenceKeys.financialLastTool);
    for (final tool in FinancialToolId.values) {
      if (_toolStoredValue(tool) == stored) return tool;
    }
    return null;
  }

  @override
  Future<void> setLastFinancialTool(FinancialToolId tool) => _preferences
      .setString(PreferenceKeys.financialLastTool, _toolStoredValue(tool));

  static String _toolStoredValue(FinancialToolId tool) => switch (tool) {
    FinancialToolId.emi => 'emi',
    FinancialToolId.simpleInterest => 'simple_interest',
    FinancialToolId.compoundInterest => 'compound_interest',
    FinancialToolId.gst => 'gst',
    FinancialToolId.discount => 'discount',
    FinancialToolId.tip => 'tip',
    FinancialToolId.percentage => 'percentage',
  };

  static String _storedValue(ThemePreference preference) =>
      switch (preference) {
        ThemePreference.system => 'system',
        ThemePreference.light => 'light',
        ThemePreference.dark => 'dark',
      };
}
