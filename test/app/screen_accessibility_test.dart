// Runs Flutter's accessibility guidelines over every real screen (the six
// modes, History, Settings and the mode sheet) in all four themes, at phone
// size. The gallery test (test/gallery/) covers the components on their own.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/shell/mode_picker.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(useInMemoryPreferences);

  const themes = {
    'light': (ThemePreference.light, false),
    'dark': (ThemePreference.dark, false),
    'high-contrast light': (ThemePreference.light, true),
    'high-contrast dark': (ThemePreference.dark, true),
  };

  Future<void> pumpScreen(
    WidgetTester tester, {
    required ThemePreference theme,
    required bool highContrast,
    Size size = TestWindows.phonePortrait,
  }) async {
    final preferences = await openPreferences();
    final settings = PreferencesSettingsRepository(preferences);
    await settings.setThemePreference(theme);
    await settings.setHighContrast(enabled: highContrast);
    await pumpApp(tester, size: size, preferences: preferences);
  }

  Future<void> expectGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  for (final MapEntry(key: themeName, value: (theme, highContrast))
      in themes.entries) {
    group('$themeName theme', () {
      for (final mode in CalculatorMode.values) {
        testWidgets('${mode.name} meets the guidelines', (tester) async {
          await pumpScreen(tester, theme: theme, highContrast: highContrast);
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
              .read(currentModeProvider.notifier)
              .select(mode);
          await tester.pumpAndSettle();

          await expectGuidelines(tester);
        });
      }

      testWidgets('the mode sheet meets the guidelines', (tester) async {
        await pumpScreen(tester, theme: theme, highContrast: highContrast);
        await tester.tap(find.byType(ModePickerButton));
        await tester.pumpAndSettle();

        await expectGuidelines(tester);
      });

      testWidgets('History meets the guidelines', (tester) async {
        await pumpScreen(tester, theme: theme, highContrast: highContrast);
        await tester.tap(find.byTooltip(l10n.historyTitle));
        await tester.pumpAndSettle();

        await expectGuidelines(tester);
      });

      testWidgets('Settings meets the guidelines', (tester) async {
        // Tall enough to lay out the whole page at once.
        await pumpScreen(
          tester,
          theme: theme,
          highContrast: highContrast,
          size: const Size(390, 4000),
        );
        await tester.tap(find.byTooltip(l10n.settingsTitle));
        await tester.pumpAndSettle();

        await expectGuidelines(tester);
      });
    });
  }
}
