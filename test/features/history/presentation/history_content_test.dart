import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/app_root.dart';
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_view.dart';
import 'package:smart_calculator/features/history/presentation/history_content.dart';
import 'package:smart_calculator/features/history/presentation/history_page.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUp(useInMemoryPreferences);

  // The test environment has no default clipboard handler: Clipboard.setData
  // and Clipboard.getData would hang forever without one (the same mock the
  // paste tests use, see calculator_view_test.dart).
  setUp(() {
    String? clipboard;
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              clipboard = (call.arguments as Map)['text'] as String?;
            case 'Clipboard.getData':
              return <String, Object?>{'text': clipboard};
          }
          return null;
        });
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Opens the calculator, computes [keys], then opens the history page.
  Future<void> pumpWithOneEntry(
    WidgetTester tester,
    String keys, {
    Size size = TestWindows.phonePortrait,
  }) async {
    await pumpApp(tester, size: size);
    for (final key in keys.split('')) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();
  }

  testWidgets('a history that cannot be read says so in plain words, and '
      '"Try again" loads it', (tester) async {
    sqfliteFfiInit();
    var failing = true;
    tester.view
      ..physicalSize = TestWindows.phonePortrait
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppRoot(
        preferences: await openPreferences(),
        overrides: [
          appDatabaseProvider.overrideWith((ref) async {
            if (failing) throw StateError('database disk image is malformed');
            return AppDatabase.open(
              databaseFactoryFfiNoIsolate,
              inMemoryDatabasePath,
              singleInstance: false,
            );
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();

    expect(find.text(l10n.historyLoadErrorTitle), findsOneWidget);
    expect(find.textContaining('malformed'), findsNothing);

    failing = false;
    await tester.tap(find.text(l10n.loadRetryAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.historyLoadErrorTitle), findsNothing);
    expect(find.text(l10n.historyEmptyTitle), findsOneWidget);
  });

  testWidgets('starts empty', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();

    expect(find.text(l10n.historyEmptyTitle), findsOneWidget);
  });

  testWidgets('a computed result appears', (tester) async {
    await pumpWithOneEntry(tester, '5+3');

    expect(find.text('5+3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text(l10n.historyEmptyTitle), findsNothing);
  });

  testWidgets('tapping an entry reuses the result and returns (pushed page)', (
    tester,
  ) async {
    await pumpWithOneEntry(tester, '5+3');

    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryPage), findsNothing);
    expect(find.byType(CalculatorView), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('search filters by expression and by result', (tester) async {
    await pumpApp(tester);
    for (final expression in ['5+3', '2×2']) {
      for (final key in expression.split('')) {
        await tester.tap(find.text(key));
        await tester.pump();
      }
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.keyAllClear));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, l10n.historySearchLabel),
      '5+3',
    );
    await tester.pumpAndSettle();

    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('a search matching nothing shows its own empty state', (
    tester,
  ) async {
    await pumpWithOneEntry(tester, '5+3');

    await tester.enterText(
      find.widgetWithText(TextField, l10n.historySearchLabel),
      'nonsense',
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.historySearchEmptyMessage), findsOneWidget);
  });

  testWidgets('copy puts the result text on the clipboard', (tester) async {
    await pumpWithOneEntry(tester, '5+3');

    await tester.tap(find.byTooltip(l10n.historyCopyTooltip));
    await tester.pump();

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, '8');
    expect(find.text(l10n.historyCopiedMessage('8')), findsOneWidget);
  });

  testWidgets('delete removes just that entry', (tester) async {
    await pumpWithOneEntry(tester, '5+3');

    await tester.tap(find.byTooltip(l10n.historyDeleteTooltip));
    await tester.pumpAndSettle();

    expect(find.text('8'), findsNothing);
    expect(find.text(l10n.historyEmptyTitle), findsOneWidget);
  });

  testWidgets('clear all asks for confirmation before clearing', (
    tester,
  ) async {
    await pumpWithOneEntry(tester, '5+3');

    await tester.tap(find.byTooltip(l10n.historyClearAllTooltip));
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsOneWidget);

    await tester.tap(
      find.text(
        MaterialLocalizations.of(tester.element(find.byType(AppDialog)))
            .cancelButtonLabel,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.historyClearAllTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.historyClearAllConfirmAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.historyEmptyTitle), findsOneWidget);
  });

  testWidgets('the clear-all button is disabled when history is empty', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();

    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(l10n.historyClearAllTooltip),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('an entry on an expanded window (panel) reuses without popping', (
    tester,
  ) async {
    // Expanded windows show the history panel directly; there's no
    // history action to tap (DEC-042), so this doesn't use
    // pumpWithOneEntry.
    await pumpApp(tester, size: TestWindows.tabletLandscape);
    for (final key in '5+3'.split('')) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(HistoryContent),
        matching: find.text('8'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HistoryContent), findsOneWidget);
    expect(find.byType(CalculatorView), findsOneWidget);
    // Both the display and the history row show 8 now.
    expect(find.text('8'), findsNWidgets(2));
  });

  testWidgets(
    'a phone-width entry with its 3 actions (save, copy, delete) fits at '
    '200% text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpWithOneEntry(tester, '5+3');

      expect(tester.takeException(), isNull);
      expect(find.byTooltip(l10n.savedSaveTooltip), findsOneWidget);
      expect(find.byTooltip(l10n.historyCopyTooltip), findsOneWidget);
      expect(find.byTooltip(l10n.historyDeleteTooltip), findsOneWidget);
    },
  );
}
