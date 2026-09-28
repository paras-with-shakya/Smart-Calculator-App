import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/shell/app_shell.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/settings/application/theme_preference_notifier.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

import '../../helpers/test_app.dart';

void main() {
  setUp(useInMemoryPreferences);

  test(
    'the notifier starts from the saved preference and saves changes',
    () async {
      final preferences = await openPreferences();
      await PreferencesSettingsRepository(preferences)
          .setThemePreference(ThemePreference.light);
      final container = ProviderContainer.test(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );

      expect(container.read(themePreferenceProvider), ThemePreference.light);

      await container
          .read(themePreferenceProvider.notifier)
          .setPreference(ThemePreference.dark);

      expect(container.read(themePreferenceProvider), ThemePreference.dark);
      expect(
        PreferencesSettingsRepository(preferences).themePreference,
        ThemePreference.dark,
      );
    },
  );

  testWidgets(
    'choosing Dark in settings applies it, and it survives a restart',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip(l10n.settingsTitle));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.themeDark));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );

      // Restart: tear the app down, then start it again from the same store.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester, preferences: await openPreferences());

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        Theme.of(tester.element(find.byType(AppShell))).brightness,
        Brightness.dark,
      );
    },
  );
}
