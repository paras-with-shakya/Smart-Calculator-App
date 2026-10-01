import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
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

  group('converter: last category', () {
    test('is null when nothing is saved', () {
      expect(repository.lastConverterCategory, isNull);
    });

    test('saves and reads back every category', () async {
      for (final category in ConversionCategoryId.values) {
        await repository.setLastConverterCategory(category);
        expect(repository.lastConverterCategory, category);
      }
    });

    test('is stored as a fixed string under its settings key', () async {
      await repository.setLastConverterCategory(ConversionCategoryId.weight);

      expect(
        preferences.getString(PreferenceKeys.converterLastCategory),
        'weight',
      );
    });

    test('falls back to null for an unrecognised stored value', () async {
      await preferences.setString(
        PreferenceKeys.converterLastCategory,
        'volume2',
      );

      expect(repository.lastConverterCategory, isNull);
    });
  });

  group('converter: last units', () {
    test('is null when nothing is saved', () {
      expect(repository.lastConverterUnits, isNull);
    });

    test('is null when only one of the two is saved', () async {
      await preferences.setString(PreferenceKeys.converterLastFromUnit, 'km');

      expect(repository.lastConverterUnits, isNull);
    });

    test('saves and reads back both units', () async {
      await repository.setLastConverterUnits('km', 'mile');

      expect(repository.lastConverterUnits, ('km', 'mile'));
    });
  });

  group('converter: currency rate', () {
    test('is the starting example rate when nothing is saved', () {
      expect(repository.currencyRate('inr'), 83);
      expect(repository.currencyRate('eur'), 0.9);
      expect(repository.currencyRate('gbp'), 0.8);
    });

    test('usd always reads 1, regardless of what is "set"', () async {
      await repository.setCurrencyRate('usd', 99);

      expect(repository.currencyRate('usd'), 1);
    });

    test('saves and reads back a rate', () async {
      await repository.setCurrencyRate('inr', 90);

      expect(repository.currencyRate('inr'), 90);
    });

    test(
      'survives a repository round-trip with fractional precision',
      () async {
        await repository.setCurrencyRate('eur', 0.9123456);

        expect(repository.currencyRate('eur'), 0.9123456);
      },
    );
  });

  group('financial: last tool', () {
    test('is null when nothing is saved', () {
      expect(repository.lastFinancialTool, isNull);
    });

    test('saves and reads back every tool', () async {
      for (final tool in FinancialToolId.values) {
        await repository.setLastFinancialTool(tool);
        expect(repository.lastFinancialTool, tool);
      }
    });

    test('is stored as a fixed string under its settings key', () async {
      await repository.setLastFinancialTool(FinancialToolId.gst);

      expect(preferences.getString(PreferenceKeys.financialLastTool), 'gst');
    });

    test('falls back to null for an unrecognised stored value', () async {
      await preferences.setString(PreferenceKeys.financialLastTool, 'emi2');

      expect(repository.lastFinancialTool, isNull);
    });
  });
}
