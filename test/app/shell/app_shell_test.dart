import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/shell/mode_picker.dart';
import 'package:smart_calculator/features/history/presentation/history_panel.dart';

import '../../helpers/test_app.dart';

void main() {
  setUp(useInMemoryPreferences);

  Finder inRail(String text) => find.descendant(
    of: find.byType(NavigationRail),
    matching: find.text(text),
  );

  int selectedRailIndex(WidgetTester tester) =>
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex!;

  group('compact window (phone in portrait)', () {
    testWidgets('shows the mode pill and header actions, and no rail', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(ModePickerButton), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byTooltip(l10n.historyTitle), findsOneWidget);
      expect(find.byTooltip(l10n.settingsTitle), findsOneWidget);
    });

    testWidgets(
      'the mode sheet lists every mode and switches to the chosen one',
      (tester) async {
        await pumpApp(tester);

        await tester.tap(find.byType(ModePickerButton));
        await tester.pumpAndSettle();
        for (final mode in CalculatorMode.values) {
          expect(
            find.widgetWithText(ListTile, mode.label(l10n)),
            findsOneWidget,
          );
        }

        await tester.tap(find.widgetWithText(ListTile, l10n.modeScientific));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);
        expect(
          find.descendant(
            of: find.byType(ModePickerButton),
            matching: find.text(l10n.modeScientific),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('lays out without overflow at 200% text size', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('medium window (tablet in portrait)', () {
    testWidgets('shows a rail of every mode instead of the mode pill', (
      tester,
    ) async {
      await pumpApp(tester, size: TestWindows.tabletPortrait);

      expect(find.byType(ModePickerButton), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations, hasLength(CalculatorMode.values.length));
      expect(find.byType(HistoryPanel), findsNothing);
      expect(find.byTooltip(l10n.historyTitle), findsOneWidget);
    });

    testWidgets('choosing a rail destination switches mode', (tester) async {
      await pumpApp(tester, size: TestWindows.tabletPortrait);

      await tester.tap(inRail(l10n.modeFinance));
      await tester.pumpAndSettle();

      expect(selectedRailIndex(tester), CalculatorMode.finance.index);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(l10n.modeFinance),
        ),
        findsOneWidget,
      );
    });
  });

  group('expanded window', () {
    testWidgets(
      'tablet in landscape: rail and history panel, no history action',
      (tester) async {
        await pumpApp(tester, size: TestWindows.tabletLandscape);

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(HistoryPanel), findsOneWidget);
        expect(find.byTooltip(l10n.historyTitle), findsNothing);
      },
    );

    testWidgets('phone in landscape: the rail scrolls to reach every mode', (
      tester,
    ) async {
      await pumpApp(tester, size: TestWindows.phoneLandscape);
      expect(tester.takeException(), isNull);

      final lastMode = inRail(CalculatorMode.values.last.label(l10n));
      await tester.ensureVisible(lastMode);
      await tester.pumpAndSettle();
      await tester.tap(lastMode);
      await tester.pumpAndSettle();

      expect(selectedRailIndex(tester), CalculatorMode.values.last.index);
    });
  });
}
