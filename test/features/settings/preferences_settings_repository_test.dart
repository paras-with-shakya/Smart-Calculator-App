import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

import '../../helpers/test_app.dart';

void main() {
  late SharedPreferencesWithCache preferences;
  late PreferencesSettingsRepository repository;

  setUp(() async {
    useInMemoryPreferences();
    preferences = await openPreferences();
    repository = PreferencesSettingsRepository(preferences);
  });

  test('follows the system theme when nothing is saved', () {
    expect(repository.themePreference, ThemePreference.system);
  });

  test('saves and reads back every theme preference', () async {
    for (final preference in ThemePreference.values) {
      await repository.setThemePreference(preference);
      expect(repository.themePreference, preference);
    }
  });

  test(
    'stores the preference as a fixed string under its settings key',
    () async {
      await repository.setThemePreference(ThemePreference.dark);

      expect(preferences.getString(PreferenceKeys.themePreference), 'dark');
    },
  );

  test(
    'falls back to the system theme for an unrecognised stored value',
    () async {
      await preferences.setString(PreferenceKeys.themePreference, 'sepia');

      expect(repository.themePreference, ThemePreference.system);
    },
  );
  group('angle mode', () {
    test('is degrees when nothing is saved', () {
      expect(repository.angleMode, AngleMode.degrees);
    });

    test('saves and reads back both modes', () async {
      for (final mode in AngleMode.values) {
        await repository.setAngleMode(mode);
        expect(repository.angleMode, mode);
      }
    });

    test('is stored as a fixed string under its settings key', () async {
      await repository.setAngleMode(AngleMode.radians);

      expect(preferences.getString(PreferenceKeys.angleMode), 'radians');
    });

    test('falls back to degrees for an unrecognised stored value', () async {
      await preferences.setString(PreferenceKeys.angleMode, 'gradians');

      expect(repository.angleMode, AngleMode.degrees);
    });
  });
}
