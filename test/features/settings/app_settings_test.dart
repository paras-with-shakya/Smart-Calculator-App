import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';

import '../../helpers/test_app.dart';

void main() {
  late SharedPreferencesWithCache preferences;
  late PreferencesSettingsRepository repository;

  setUp(() async {
    useInMemoryPreferences();
    preferences = await openPreferences();
    repository = PreferencesSettingsRepository(preferences);
  });

  group('defaults are the behaviour before Phase 10', () {
    test('a fresh install', () {
      const settings = AppSettings();
      expect(repository.appSettings, settings);
      expect(settings.defaultMode, CalculatorMode.basic);
      expect(settings.haptics, isTrue);
      expect(settings.keySound, isTrue);
      expect(settings.decimalPlaces, DecimalPlaces.auto);
      expect(settings.historyEnabled, isTrue);
      expect(settings.historyLimit, HistoryLimit.unlimited);
      expect(settings.textSize, TextSize.normal);
      expect(settings.largerControls, isFalse);
      expect(settings.highContrast, isFalse);
    });

    test('the enums carry the numbers they are named for', () {
      expect(
        [for (final p in DecimalPlaces.values) p.places],
        [null, 2, 4, 6, 8],
      );
      expect(
        [for (final l in HistoryLimit.values) l.keep],
        [50, 100, 500, null],
      );
      expect([for (final t in TextSize.values) t.multiplier], [1, 1.15, 1.3]);
    });
  });

  group('round trips', () {
    test('every default mode', () async {
      for (final mode in CalculatorMode.values) {
        await repository.setDefaultMode(mode);
        expect(repository.appSettings.defaultMode, mode);
      }
    });

    test('every decimal-places choice', () async {
      for (final places in DecimalPlaces.values) {
        await repository.setDecimalPlaces(places);
        expect(repository.appSettings.decimalPlaces, places);
      }
    });

    test('every history limit', () async {
      for (final limit in HistoryLimit.values) {
        await repository.setHistoryLimit(limit);
        expect(repository.appSettings.historyLimit, limit);
      }
    });

    test('every text size', () async {
      for (final size in TextSize.values) {
        await repository.setTextSize(size);
        expect(repository.appSettings.textSize, size);
      }
    });

    test('every switch, both ways', () async {
      for (final enabled in [false, true]) {
        await repository.setHaptics(enabled: enabled);
        await repository.setKeySound(enabled: enabled);
        await repository.setHistoryEnabled(enabled: enabled);
        await repository.setLargerControls(enabled: enabled);
        await repository.setHighContrast(enabled: enabled);
        final settings = repository.appSettings;
        expect(settings.haptics, enabled);
        expect(settings.keySound, enabled);
        expect(settings.historyEnabled, enabled);
        expect(settings.largerControls, enabled);
        expect(settings.highContrast, enabled);
      }
    });

    test(
      'values are stored as fixed strings, bools and settings keys',
      () async {
        await repository.setDefaultMode(CalculatorMode.programmer);
        await repository.setDecimalPlaces(DecimalPlaces.four);
        await repository.setHistoryLimit(HistoryLimit.fiveHundred);
        await repository.setTextSize(TextSize.large);
        await repository.setHaptics(enabled: false);

        expect(preferences.getString(PreferenceKeys.defaultMode), 'programmer');
        expect(preferences.getString(PreferenceKeys.decimalPlaces), '4');
        expect(preferences.getString(PreferenceKeys.historyLimit), '500');
        expect(preferences.getString(PreferenceKeys.textSize), '115');
        expect(preferences.getBool(PreferenceKeys.haptics), isFalse);
      },
    );

    test('one setting never disturbs another', () async {
      await repository.setTextSize(TextSize.larger);
      await repository.setLargerControls(enabled: true);

      final settings = repository.appSettings;
      expect(settings.textSize, TextSize.larger);
      expect(settings.largerControls, isTrue);
      expect(settings.highContrast, isFalse);
      expect(settings.defaultMode, CalculatorMode.basic);
    });

    test('every key is in the preferences allow-list', () {
      for (final key in [
        PreferenceKeys.defaultMode,
        PreferenceKeys.haptics,
        PreferenceKeys.keySound,
        PreferenceKeys.decimalPlaces,
        PreferenceKeys.historyEnabled,
        PreferenceKeys.historyLimit,
        PreferenceKeys.textSize,
        PreferenceKeys.largerControls,
        PreferenceKeys.highContrast,
      ]) {
        expect(PreferenceKeys.all, contains(key));
        expect(key, startsWith('settings.'));
      }
    });
  });

  group('damaged preferences fall back to the defaults', () {
    test('unrecognised strings', () async {
      await preferences.setString(PreferenceKeys.defaultMode, 'turbo');
      await preferences.setString(PreferenceKeys.decimalPlaces, '3');
      await preferences.setString(PreferenceKeys.historyLimit, 'many');
      await preferences.setString(PreferenceKeys.textSize, '999');

      final settings = repository.appSettings;
      expect(settings.defaultMode, CalculatorMode.basic);
      expect(settings.decimalPlaces, DecimalPlaces.auto);
      expect(settings.historyLimit, HistoryLimit.unlimited);
      expect(settings.textSize, TextSize.normal);
    });

    test('values of the wrong type do not throw', () async {
      await preferences.setBool(PreferenceKeys.defaultMode, true);
      await preferences.setInt(PreferenceKeys.decimalPlaces, 2);
      await preferences.setString(PreferenceKeys.haptics, 'yes');
      await preferences.setInt(PreferenceKeys.keySound, 0);
      await preferences.setString(PreferenceKeys.historyEnabled, 'false');
      await preferences.setBool(PreferenceKeys.historyLimit, false);
      await preferences.setDouble(PreferenceKeys.textSize, 1.3);
      await preferences.setString(PreferenceKeys.largerControls, 'on');
      await preferences.setInt(PreferenceKeys.highContrast, 1);

      expect(repository.appSettings, const AppSettings());
    });

    test('the theme and angle readers survive a wrong type too', () async {
      await preferences.setInt(PreferenceKeys.themePreference, 3);
      await preferences.setBool(PreferenceKeys.angleMode, true);

      expect(repository.themePreference.name, 'system');
      expect(repository.angleMode.name, 'degrees');
    });
  });

  group('AppSettingsNotifier', () {
    ProviderContainer container() {
      final container = ProviderContainer.test(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      return container;
    }

    test('starts from what is stored', () async {
      await repository.setDefaultMode(CalculatorMode.date);
      await repository.setLargerControls(enabled: true);

      final settings = container().read(appSettingsProvider);
      expect(settings.defaultMode, CalculatorMode.date);
      expect(settings.largerControls, isTrue);
    });

    test('saves first, then updates the state', () async {
      final c = container();
      final future = c
          .read(appSettingsProvider.notifier)
          .setTextSize(TextSize.large);
      // Not applied before the save has finished.
      expect(c.read(appSettingsProvider).textSize, TextSize.normal);
      await future;

      expect(c.read(appSettingsProvider).textSize, TextSize.large);
      expect(repository.appSettings.textSize, TextSize.large);
    });

    test('every setter updates only its own field', () async {
      final c = container();
      final notifier = c.read(appSettingsProvider.notifier);

      await notifier.setDefaultMode(CalculatorMode.scientific);
      await notifier.setHaptics(enabled: false);
      await notifier.setKeySound(enabled: false);
      await notifier.setDecimalPlaces(DecimalPlaces.six);
      await notifier.setHistoryEnabled(enabled: false);
      await notifier.setHistoryLimit(HistoryLimit.hundred);
      await notifier.setTextSize(TextSize.larger);
      await notifier.setLargerControls(enabled: true);
      await notifier.setHighContrast(enabled: true);

      const expected = AppSettings(
        defaultMode: CalculatorMode.scientific,
        haptics: false,
        keySound: false,
        decimalPlaces: DecimalPlaces.six,
        historyEnabled: false,
        historyLimit: HistoryLimit.hundred,
        textSize: TextSize.larger,
        largerControls: true,
        highContrast: true,
      );
      expect(c.read(appSettingsProvider), expected);
      expect(repository.appSettings, expected);
    });

    test('two changes started together both survive', () async {
      final c = container();
      final notifier = c.read(appSettingsProvider.notifier);

      await Future.wait([
        notifier.setTextSize(TextSize.large),
        notifier.setLargerControls(enabled: true),
        notifier.setHighContrast(enabled: true),
      ]);

      final settings = c.read(appSettingsProvider);
      expect(settings.textSize, TextSize.large);
      expect(settings.largerControls, isTrue);
      expect(settings.highContrast, isTrue);
    });

    test('setting a value it already has does not write', () async {
      final c = container();
      await c.read(appSettingsProvider.notifier).setHaptics(enabled: true);

      expect(preferences.containsKey(PreferenceKeys.haptics), isFalse);
    });

    test('a fresh container reads back what was saved (a restart)', () async {
      await container()
          .read(appSettingsProvider.notifier)
          .setDecimalPlaces(DecimalPlaces.two);

      expect(
        container().read(appSettingsProvider).decimalPlaces,
        DecimalPlaces.two,
      );
    });

    test('select rebuilds only for the field it watches', () async {
      final c = container();
      var hapticsReads = 0;
      c.listen(appSettingsProvider.select((s) => s.haptics), (_, _) {
        hapticsReads++;
      });

      final notifier = c.read(appSettingsProvider.notifier);
      await notifier.setTextSize(TextSize.large);
      await notifier.setHighContrast(enabled: true);
      expect(hapticsReads, 0);
      await notifier.setHaptics(enabled: false);
      expect(hapticsReads, 1);
    });
  });
}
