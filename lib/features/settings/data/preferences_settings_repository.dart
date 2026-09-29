import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
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

  static String _storedValue(ThemePreference preference) =>
      switch (preference) {
        ThemePreference.system => 'system',
        ThemePreference.light => 'light',
        ThemePreference.dark => 'dark',
      };
}
