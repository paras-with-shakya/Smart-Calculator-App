import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_view.dart';
import 'package:smart_calculator/features/history/presentation/history_content.dart';
import 'package:smart_calculator/features/history/presentation/history_page.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUp(useInMemoryPreferences);

  /// Opens the calculator, computes [keys], opens history, then switches to
  /// the Saved tab (after saving the one entry, if [save] is true).
  Future<void> pumpOnSavedTab(
    WidgetTester tester,
    String keys, {
    bool save = true,
  }) async {
    await pumpApp(tester);
    for (final key in keys.split('')) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();
    if (save) {
      await tester.tap(find.byTooltip(l10n.savedSaveTooltip));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, l10n.savedNameLabel),
        'My calculation',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.savedSaveAction));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(l10n.savedTabLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('starts empty', (tester) async {
    await pumpOnSavedTab(tester, '5+3', save: false);

    expect(find.text(l10n.savedEmptyTitle), findsOneWidget);
  });

  testWidgets('saving a history entry adds it, under the given name', (
    tester,
  ) async {
    await pumpOnSavedTab(tester, '5+3');

    expect(find.text('My calculation'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text(l10n.savedEmptyTitle), findsNothing);
  });

  testWidgets('the save button requires a non-empty name', (tester) async {
    await pumpApp(tester);
    for (final key in '5+3'.split('')) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.savedSaveTooltip));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(l10n.savedSaveAction),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping a saved entry reuses the result and returns', (
    tester,
  ) async {
    await pumpOnSavedTab(tester, '5+3');

    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryPage), findsNothing);
    expect(find.byType(CalculatorView), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('rename changes the name and keeps the entry', (tester) async {
    await pumpOnSavedTab(tester, '5+3');

    await tester.tap(find.byTooltip(l10n.savedRenameTooltip));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.savedNameLabel),
      'Renamed calculation',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.savedRenameAction));
    await tester.pumpAndSettle();

    expect(find.text('Renamed calculation'), findsOneWidget);
    expect(find.text('My calculation'), findsNothing);
  });

  testWidgets('delete removes just that entry', (tester) async {
    await pumpOnSavedTab(tester, '5+3');

    await tester.tap(find.byTooltip(l10n.savedDeleteTooltip));
    await tester.pumpAndSettle();

    expect(find.text('My calculation'), findsNothing);
    expect(find.text(l10n.savedEmptyTitle), findsOneWidget);
  });

  testWidgets('search filters by name, expression and result', (tester) async {
    await pumpOnSavedTab(tester, '5+3');

    await tester.enterText(
      find.widgetWithText(TextField, l10n.savedSearchLabel),
      'nonsense',
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.savedSearchEmptyMessage), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, l10n.savedSearchLabel),
      'My calc',
    );
    await tester.pumpAndSettle();
    expect(find.text('My calculation'), findsOneWidget);
  });

  testWidgets('clear all asks for confirmation before clearing', (
    tester,
  ) async {
    await pumpOnSavedTab(tester, '5+3');

    await tester.tap(find.byTooltip(l10n.savedClearAllTooltip));
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsOneWidget);

    await tester.tap(
      find.text(
        MaterialLocalizations.of(tester.element(find.byType(AppDialog)))
            .cancelButtonLabel,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My calculation'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.savedClearAllTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.savedClearAllConfirmAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.savedEmptyTitle), findsOneWidget);
  });

  testWidgets('switching tabs clears the search field', (tester) async {
    await pumpOnSavedTab(tester, '5+3');
    await tester.enterText(
      find.widgetWithText(TextField, l10n.savedSearchLabel),
      'nonsense',
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.savedSearchEmptyMessage), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(HistoryContent),
        matching: find.text(l10n.historyTabLabel),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('8'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, l10n.historySearchLabel),
      findsOneWidget,
    );
  });
}
