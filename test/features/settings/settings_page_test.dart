import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/core/app_info.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
import 'package:smart_calculator/features/history/data/sqflite_history_repository.dart';
import 'package:smart_calculator/features/settings/application/angle_mode_notifier.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';
import 'package:smart_calculator/features/settings/presentation/settings_page.dart';

import '../../helpers/test_app.dart';

/// Tall enough that the whole list is built at once (a ListView builds only
/// what is near the screen).
const Size tallPhone = Size(400, 4800);

void main() {
  setUp(useInMemoryPreferences);

  late ProviderContainer container;

  Future<void> openSettings(WidgetTester tester, {Size? size}) async {
    await pumpApp(tester, size: size ?? tallPhone);
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    await tester.tap(find.byTooltip(l10n.settingsTitle));
    await tester.pumpAndSettle();
  }

  Finder switchTile(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byType(SwitchListTile),
  );

  Future<void> tapSwitch(WidgetTester tester, String title) async {
    await tester.tap(switchTile(title));
    await tester.pumpAndSettle();
  }

  AppSettings settings() => container.read(appSettingsProvider);

  /// The option labelled [label] of the one choice group whose options
  /// include it (several groups share labels such as "100").
  Future<void> tapChoice(
    WidgetTester tester,
    String groupLabel,
    String label,
  ) async {
    final row = find.ancestor(
      of: find.text(groupLabel),
      matching: find.byType(Column),
    );
    await tester.tap(
      find.descendant(of: row.first, matching: find.text(label)).first,
    );
    await tester.pumpAndSettle();
  }

  /// Opens the sheet of the row labelled [rowLabel] and picks [label] in it.
  Future<void> pickFromSheet(
    WidgetTester tester,
    String rowLabel,
    String label,
  ) async {
    final row = find.ancestor(
      of: find.text(rowLabel),
      matching: find.byType(Column),
    );
    await tester.tap(
      find.descendant(of: row.first, matching: find.byType(AppButton)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('shows every section and setting', (tester) async {
      await openSettings(tester);

      for (final text in [
        l10n.settingsAppearanceSection,
        l10n.settingsCalculatorSection,
        l10n.settingsHistorySection,
        l10n.settingsAccessibilitySection,
        l10n.settingsAboutSection,
        l10n.settingsThemeLabel,
        l10n.settingsDefaultModeLabel,
        l10n.settingsAngleModeLabel,
        l10n.settingsDecimalPlacesLabel,
        l10n.settingsHapticsLabel,
        l10n.settingsKeySoundLabel,
        l10n.settingsHistoryEnabledLabel,
        l10n.settingsHistoryLimitLabel,
        l10n.settingsTextSizeLabel,
        l10n.settingsLargerControlsLabel,
        l10n.settingsHighContrastLabel,
        l10n.settingsVersionLabel,
        l10n.settingsPrivacyTitle,
        l10n.settingsLicensesLabel,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text(l10n.settingsClearHistoryLabel), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('section headings are headings for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openSettings(tester);

      for (final title in [
        l10n.settingsCalculatorSection,
        l10n.settingsHistorySection,
        l10n.settingsAccessibilitySection,
        l10n.settingsAboutSection,
      ]) {
        expect(
          tester.getSemantics(find.text(title)),
          isSemantics(label: title, isHeader: true),
        );
      }
      handle.dispose();
    });

    testWidgets('defaults match the behaviour before Phase 10', (tester) async {
      await openSettings(tester);

      expect(settings(), const AppSettings());
      expect(
        tester
            .widget<SwitchListTile>(switchTile(l10n.settingsHapticsLabel))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<SwitchListTile>(switchTile(l10n.settingsKeySoundLabel))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              switchTile(l10n.settingsHistoryEnabledLabel),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              switchTile(l10n.settingsLargerControlsLabel),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<SwitchListTile>(switchTile(l10n.settingsHighContrastLabel))
            .value,
        isFalse,
      );
    });

    for (final (name, size) in [
      ('phone', const Size(360, 800)),
      ('landscape', const Size(800, 360)),
      ('tablet', const Size(1280, 800)),
    ]) {
      testWidgets('$name: no overflow, the column never passes 480 dp', (
        tester,
      ) async {
        await openSettings(tester, size: size);

        expect(tester.takeException(), isNull);
        final card = find.byType(Card);
        if (card.evaluate().isNotEmpty) {
          expect(
            tester
                .getSize(find.byType(SegmentedButton<ThemePreference>).first)
                .width,
            lessThanOrEqualTo(SettingsPage.maxContentWidth),
          );
        }
      });
    }

    testWidgets('200% text: no overflow, every control still reachable', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSettings(tester, size: const Size(360, 4000));

      expect(tester.takeException(), isNull);
      // The page is taller than the window at this size: scroll to reach it.
      await tester.scrollUntilVisible(find.text('115%'), 500);
      await tester.ensureVisible(find.text('115%'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('115%'));
      await tester.pumpAndSettle();
      expect(settings().textSize, TextSize.large);
    });

    testWidgets('every switch row is at least 48 dp tall', (tester) async {
      await openSettings(tester);

      for (final element in find.byType(SwitchListTile).evaluate()) {
        final box = element.renderObject! as RenderBox;
        expect(box.size.height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('calculator', () {
    testWidgets('the default mode: pick one, it is saved, and the app opens '
        'in it next time', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text(l10n.modeBasic).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(l10n.modeProgrammer),
        ),
      );
      await tester.pumpAndSettle();

      expect(settings().defaultMode, CalculatorMode.programmer);
      expect(find.byType(BottomSheet), findsNothing);
      // The mode on screen is untouched.
      expect(container.read(currentModeProvider), CalculatorMode.basic);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester, preferences: await openPreferences());
      final restarted = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      expect(restarted.read(currentModeProvider), CalculatorMode.programmer);
    });

    testWidgets('the angle unit', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text(l10n.settingsAngleRadians));
      await tester.pumpAndSettle();
      expect(container.read(angleModeProvider), AngleMode.radians);

      await tester.tap(find.text(l10n.settingsAngleDegrees));
      await tester.pumpAndSettle();
      expect(container.read(angleModeProvider), AngleMode.degrees);
    });

    testWidgets('decimal places', (tester) async {
      await openSettings(tester);

      // Five choices do not fit side by side: the row opens them in a sheet.
      await pickFromSheet(tester, l10n.settingsDecimalPlacesLabel, '4');
      expect(settings().decimalPlaces, DecimalPlaces.four);
      expect(find.byType(BottomSheet), findsNothing);
      // The row now shows the current choice.
      expect(find.widgetWithText(AppButton, '4'), findsOneWidget);

      await pickFromSheet(
        tester,
        l10n.settingsDecimalPlacesLabel,
        l10n.settingsDecimalPlacesAuto,
      );
      expect(settings().decimalPlaces, DecimalPlaces.auto);
    });

    testWidgets('haptics and key sounds are separate switches', (tester) async {
      await openSettings(tester);

      await tapSwitch(tester, l10n.settingsHapticsLabel);
      expect(settings().haptics, isFalse);
      expect(settings().keySound, isTrue);

      await tapSwitch(tester, l10n.settingsKeySoundLabel);
      expect(settings().keySound, isFalse);

      await tapSwitch(tester, l10n.settingsHapticsLabel);
      expect(settings().haptics, isTrue);
    });

    testWidgets('a switch reads as a toggle with its title and hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openSettings(tester);

      final node = tester.getSemantics(switchTile(l10n.settingsHapticsLabel));
      expect(node.label, contains(l10n.settingsHapticsLabel));
      expect(node.label, contains(l10n.settingsHapticsHint));
      expect(
        node,
        isSemantics(hasToggledState: true, isToggled: true, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets('settings made here persist across a restart', (tester) async {
      await openSettings(tester);
      await pickFromSheet(tester, l10n.settingsDecimalPlacesLabel, '6');
      await tapSwitch(tester, l10n.settingsHapticsLabel);
      await tapSwitch(tester, l10n.settingsHighContrastLabel);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(
        tester,
        size: tallPhone,
        preferences: await openPreferences(),
      );
      container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );

      expect(settings().decimalPlaces, DecimalPlaces.six);
      expect(settings().haptics, isFalse);
      expect(settings().highContrast, isTrue);
    });
  });

  group('history', () {
    Future<SqfliteHistoryRepository> seed(int count) async {
      final repository =
          container.read(historyRepositoryProvider) as SqfliteHistoryRepository;
      for (var i = 1; i <= count; i++) {
        await repository.add(
          expression: '$i+0',
          result: CalcValue.fromInt(i),
          mode: CalculatorMode.basic,
        );
      }
      container.invalidate(historyProvider);
      await container.read(historyProvider.future);
      return repository;
    }

    testWidgets('Clear history is disabled while the history is empty', (
      tester,
    ) async {
      await openSettings(tester);

      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, l10n.settingsClearHistoryLabel),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Clear history asks first; cancel keeps everything', (
      tester,
    ) async {
      await openSettings(tester);
      await seed(3);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(AppButton, l10n.settingsClearHistoryLabel),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text(l10n.historyClearAllConfirmTitle), findsOneWidget);

      await tester.tap(
        find.text(
          MaterialLocalizations.of(tester.element(find.byType(AppDialog)))
              .cancelButtonLabel,
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(historyProvider).requireValue, hasLength(3));
    });

    testWidgets('Clear history, confirmed, empties it and says so', (
      tester,
    ) async {
      await openSettings(tester);
      await seed(3);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(AppButton, l10n.settingsClearHistoryLabel),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.historyClearAllConfirmAction));
      await tester.pumpAndSettle();

      expect(container.read(historyProvider).requireValue, isEmpty);
      expect(find.text(l10n.settingsHistoryCleared), findsOneWidget);
      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, l10n.settingsClearHistoryLabel),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('lowering the limit below the entries kept asks, then '
        'deletes the older ones', (tester) async {
      await openSettings(tester);
      final repository = await seed(60);
      await tester.pumpAndSettle();

      await pickFromSheet(tester, l10n.settingsHistoryLimitLabel, '50');
      expect(find.byType(AppDialog), findsOneWidget);
      expect(
        find.text(l10n.settingsHistoryLimitConfirmMessage(50, 10)),
        findsOneWidget,
      );
      // Nothing yet.
      expect(settings().historyLimit, HistoryLimit.unlimited);
      expect(await repository.list(), hasLength(60));

      await tester.tap(find.text(l10n.settingsHistoryLimitConfirmAction));
      await tester.pumpAndSettle();

      expect(settings().historyLimit, HistoryLimit.fifty);
      expect(await repository.list(), hasLength(50));
      expect(container.read(historyProvider).requireValue, hasLength(50));
    });

    testWidgets('cancelling the lower limit changes nothing', (tester) async {
      await openSettings(tester);
      final repository = await seed(60);
      await tester.pumpAndSettle();

      await pickFromSheet(tester, l10n.settingsHistoryLimitLabel, '50');
      await tester.tap(
        find.text(
          MaterialLocalizations.of(tester.element(find.byType(AppDialog)))
              .cancelButtonLabel,
        ),
      );
      await tester.pumpAndSettle();

      expect(settings().historyLimit, HistoryLimit.unlimited);
      expect(await repository.list(), hasLength(60));
    });

    testWidgets('a limit the entries already fit under needs no question', (
      tester,
    ) async {
      await openSettings(tester);
      await seed(5);
      await tester.pumpAndSettle();

      await pickFromSheet(tester, l10n.settingsHistoryLimitLabel, '100');

      expect(find.byType(AppDialog), findsNothing);
      expect(settings().historyLimit, HistoryLimit.hundred);
    });

    testWidgets('choosing All needs no question and keeps everything', (
      tester,
    ) async {
      await openSettings(tester);
      await seed(3);
      await tester.pumpAndSettle();
      await pickFromSheet(tester, l10n.settingsHistoryLimitLabel, '100');

      await pickFromSheet(
        tester,
        l10n.settingsHistoryLimitLabel,
        l10n.settingsHistoryLimitAll,
      );

      expect(settings().historyLimit, HistoryLimit.unlimited);
      expect(container.read(historyProvider).requireValue, hasLength(3));
    });

    testWidgets('Save history off: a calculation is not added, and the '
        'History screen says why', (tester) async {
      await openSettings(tester, size: const Size(400, 4800));
      await tapSwitch(tester, l10n.settingsHistoryEnabledLabel);
      expect(settings().historyEnabled, isFalse);

      await tester.pageBack();
      await tester.pumpAndSettle();
      for (final key in '2+3'.split('')) {
        await tester.tap(find.text(key));
        await tester.pump();
      }
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.historyTitle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.historyOffTitle), findsOneWidget);
      expect(find.text(l10n.historyOffMessage), findsOneWidget);
      expect(find.text(l10n.historyEmptyTitle), findsNothing);
    });

    testWidgets('with history off and old entries, a banner says so', (
      tester,
    ) async {
      await openSettings(tester);
      await seed(2);
      await tapSwitch(tester, l10n.settingsHistoryEnabledLabel);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.historyTitle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.historyOffBanner), findsOneWidget);
      expect(find.text('1+0'), findsOneWidget);
    });
  });

  group('accessibility', () {
    double textScale(WidgetTester tester) =>
        MediaQuery.of(tester.element(find.byType(SettingsPage))).textScaler
            .scale(10);

    testWidgets('text size applies at once, and the page stays open', (
      tester,
    ) async {
      await openSettings(tester);
      expect(textScale(tester), 10);

      await tapChoice(tester, l10n.settingsTextSizeLabel, '130%');
      expect(settings().textSize, TextSize.larger);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(textScale(tester), closeTo(13, 1e-9));

      await tapChoice(tester, l10n.settingsTextSizeLabel, '100%');
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(textScale(tester), 10);
    });

    testWidgets('larger controls apply at once, and the page stays open', (
      tester,
    ) async {
      await openSettings(tester);
      final before = tester
          .getSize(find.widgetWithText(AppButton, l10n.settingsLicensesLabel))
          .height;

      await tapSwitch(tester, l10n.settingsLargerControlsLabel);

      expect(find.byType(SettingsPage), findsOneWidget);
      final after = tester
          .getSize(find.widgetWithText(AppButton, l10n.settingsLicensesLabel))
          .height;
      expect(after, greaterThan(before));
      expect(after, greaterThanOrEqualTo(60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('high contrast applies at once, and the page stays open', (
      tester,
    ) async {
      await openSettings(tester);
      AppColors colors() =>
          AppColors.of(tester.element(find.byType(SettingsPage)));
      expect(colors(), same(AppColors.light));

      await tapSwitch(tester, l10n.settingsHighContrastLabel);

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(colors(), same(AppColors.highContrastLight));
    });

    testWidgets('all three together do not overflow the page', (tester) async {
      await openSettings(tester, size: const Size(360, 5000));
      await tapChoice(tester, l10n.settingsTextSizeLabel, '130%');
      await tapSwitch(tester, l10n.settingsLargerControlsLabel);
      await tapSwitch(tester, l10n.settingsHighContrastLabel);

      expect(tester.takeException(), isNull);
    });
  });

  group('about', () {
    testWidgets('shows the app version', (tester) async {
      await openSettings(tester);

      expect(find.text(AppInfo.displayVersion), findsOneWidget);
      expect(AppInfo.displayVersion, '1.0.0 (1)');
    });

    testWidgets('the version row is one announcement', (tester) async {
      final handle = tester.ensureSemantics();
      await openSettings(tester);

      expect(
        find.bySemanticsLabel(
          l10n.settingsVersionSemantics(AppInfo.displayVersion),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the privacy summary is shown in full', (tester) async {
      await openSettings(tester);

      for (final text in [
        l10n.settingsPrivacyInternet,
        l10n.settingsPrivacyStorage,
        l10n.settingsPrivacyRemoval,
        l10n.settingsPrivacyNotPolicy,
      ]) {
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('the licences row opens the licence page', (tester) async {
      // The default registry reads a bundled file that tests do not have.
      LicenseRegistry.reset();
      LicenseRegistry.addLicense(() async* {
        yield const LicenseEntryWithLineBreaks(['A package'], 'A licence.');
      });
      addTearDown(LicenseRegistry.reset);
      await openSettings(tester);

      await tester.tap(find.text(l10n.settingsLicensesLabel));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text(AppInfo.displayVersion), findsWidgets);
    });

    testWidgets('there is no developer information (none was given)', (
      tester,
    ) async {
      await openSettings(tester);

      expect(find.textContaining('Developer'), findsNothing);
      expect(find.textContaining('developer'), findsNothing);
    });
  });

  group('theme', () {
    testWidgets('the existing theme choice still works from the new page', (
      tester,
    ) async {
      await openSettings(tester);

      await tester.tap(find.text(l10n.themeDark));
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    });
  });
}
