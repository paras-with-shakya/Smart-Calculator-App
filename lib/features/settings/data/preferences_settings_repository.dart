import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/converter/domain/conversion_tables.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';
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

  /// The stored string for [key], or null if it is missing or not a string.
  /// `SharedPreferencesWithCache.getString` would throw on a value of another
  /// type; a damaged preferences file must never stop the app.
  String? _string(String key) {
    final value = _preferences.get(key);
    return value is String ? value : null;
  }

  /// The stored bool for [key], or [fallback] if missing or not a bool.
  bool _bool(String key, {required bool fallback}) {
    final value = _preferences.get(key);
    return value is bool ? value : fallback;
  }

  @override
  ThemePreference get themePreference {
    final stored = _string(PreferenceKeys.themePreference);
    return ThemePreference.values.firstWhere(
      (preference) => _storedValue(preference) == stored,
      orElse: () => ThemePreference.system,
    );
  }

  @override
  Future<void> setThemePreference(ThemePreference preference) => _preferences
      .setString(PreferenceKeys.themePreference, _storedValue(preference));

  @override
  AngleMode get angleMode => _string(PreferenceKeys.angleMode) == 'radians'
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
    final stored = _string(PreferenceKeys.converterLastCategory);
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
    final from = _string(PreferenceKeys.converterLastFromUnit);
    final to = _string(PreferenceKeys.converterLastToUnit);
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
    final stored = key == null ? null : _string(key);
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
    final stored = _string(PreferenceKeys.financialLastTool);
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

  @override
  AppSettings get appSettings {
    const defaults = AppSettings();
    return AppSettings(
      defaultMode: switch (_string(PreferenceKeys.defaultMode)) {
        final String id => CalculatorModeStorage.fromStorageId(id),
        null => defaults.defaultMode,
      },
      haptics: _bool(PreferenceKeys.haptics, fallback: defaults.haptics),
      keySound: _bool(PreferenceKeys.keySound, fallback: defaults.keySound),
      decimalPlaces: _fromStored(
        DecimalPlaces.values,
        _decimalPlacesStoredValue,
        _string(PreferenceKeys.decimalPlaces),
        defaults.decimalPlaces,
      ),
      historyEnabled: _bool(
        PreferenceKeys.historyEnabled,
        fallback: defaults.historyEnabled,
      ),
      historyLimit: _fromStored(
        HistoryLimit.values,
        _historyLimitStoredValue,
        _string(PreferenceKeys.historyLimit),
        defaults.historyLimit,
      ),
      textSize: _fromStored(
        TextSize.values,
        _textSizeStoredValue,
        _string(PreferenceKeys.textSize),
        defaults.textSize,
      ),
      largerControls: _bool(
        PreferenceKeys.largerControls,
        fallback: defaults.largerControls,
      ),
      highContrast: _bool(
        PreferenceKeys.highContrast,
        fallback: defaults.highContrast,
      ),
    );
  }

  @override
  Future<void> setDefaultMode(CalculatorMode mode) =>
      _preferences.setString(PreferenceKeys.defaultMode, mode.storageId);

  @override
  Future<void> setHaptics({required bool enabled}) =>
      _preferences.setBool(PreferenceKeys.haptics, enabled);

  @override
  Future<void> setKeySound({required bool enabled}) =>
      _preferences.setBool(PreferenceKeys.keySound, enabled);

  @override
  Future<void> setDecimalPlaces(DecimalPlaces places) => _preferences.setString(
    PreferenceKeys.decimalPlaces,
    _decimalPlacesStoredValue(places),
  );

  @override
  Future<void> setHistoryEnabled({required bool enabled}) =>
      _preferences.setBool(PreferenceKeys.historyEnabled, enabled);

  @override
  Future<void> setHistoryLimit(HistoryLimit limit) => _preferences.setString(
    PreferenceKeys.historyLimit,
    _historyLimitStoredValue(limit),
  );

  @override
  Future<void> setTextSize(TextSize size) => _preferences.setString(
    PreferenceKeys.textSize,
    _textSizeStoredValue(size),
  );

  @override
  Future<void> setLargerControls({required bool enabled}) =>
      _preferences.setBool(PreferenceKeys.largerControls, enabled);

  @override
  Future<void> setHighContrast({required bool enabled}) =>
      _preferences.setBool(PreferenceKeys.highContrast, enabled);

  /// The value of [values] whose stored form is [stored], or [fallback].
  static T _fromStored<T>(
    List<T> values,
    String Function(T) storedValue,
    String? stored,
    T fallback,
  ) {
    for (final value in values) {
      if (storedValue(value) == stored) return value;
    }
    return fallback;
  }

  static String _decimalPlacesStoredValue(DecimalPlaces places) =>
      switch (places) {
        DecimalPlaces.auto => 'auto',
        DecimalPlaces.two => '2',
        DecimalPlaces.four => '4',
        DecimalPlaces.six => '6',
        DecimalPlaces.eight => '8',
      };

  static String _historyLimitStoredValue(HistoryLimit limit) => switch (limit) {
    HistoryLimit.fifty => '50',
    HistoryLimit.hundred => '100',
    HistoryLimit.fiveHundred => '500',
    HistoryLimit.unlimited => 'unlimited',
  };

  static String _textSizeStoredValue(TextSize size) => switch (size) {
    TextSize.normal => '100',
    TextSize.large => '115',
    TextSize.larger => '130',
  };

  static String _storedValue(ThemePreference preference) =>
      switch (preference) {
        ThemePreference.system => 'system',
        ThemePreference.light => 'light',
        ThemePreference.dark => 'dark',
      };
}
