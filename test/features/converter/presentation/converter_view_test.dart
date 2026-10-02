import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/features/converter/presentation/category_picker.dart';
import 'package:smart_calculator/features/converter/presentation/converter_card.dart';
import 'package:smart_calculator/features/converter/presentation/converter_keypad.dart';
import 'package:smart_calculator/features/converter/presentation/converter_view.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/touch_targets.dart';

const Size phone = Size(360, 800);
const Size phoneLandscape = Size(800, 360);

Finder keypadKey(String semanticLabel) => find.byWidgetPredicate(
  (widget) =>
      widget is CalculatorButton && widget.semanticLabel == semanticLabel,
);

/// The From card is the first [ConverterCard] in the tree, the To card the
/// second — true in both the portrait and landscape layout, since both
/// build the same `_AmountCards` in the same order.
Finder fromCard() => find.byType(ConverterCard).at(0);
Finder toCard() => find.byType(ConverterCard).at(1);

/// [text] shown inside [card] — scoped, so it isn't confused with the
/// keypad's own visible digit labels (a [CalculatorButton] showing "5" is
/// also, textually, `Text('5')`).
Finder textIn(Finder card, String text) =>
    find.descendant(of: card, matching: find.text(text));

void main() {
  setUp(useInMemoryPreferences);

  /// Starts the app and switches to Converter mode, the way tapping the
  /// mode picker would.
  Future<void> pumpConverter(WidgetTester tester, {Size size = phone}) async {
    await pumpApp(tester, size: size);
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(currentModeProvider.notifier)
        .select(CalculatorMode.converter);
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] into view before tapping it — the whole screen (and
  /// the unit-picker sheet) scrolls, so a key below the fold can't be
  /// tapped by its (off-screen) centre directly.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  group('layout', () {
    testWidgets('on a 360 x 800 phone the cards and the whole keypad fit '
        'without scrolling', (tester) async {
      await pumpConverter(tester);

      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(
        tester.getRect(find.byType(ConverterKeypad)).bottom,
        lessThanOrEqualTo(screen.height),
      );
      expect(
        tester.getRect(find.byType(ConverterCard).at(0)).top,
        greaterThanOrEqualTo(0),
      );
    });

    testWidgets('portrait: renders every converter area with no exception', (
      tester,
    ) async {
      await pumpConverter(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ConverterView), findsOneWidget);
      expect(find.byType(CategoryPicker), findsOneWidget);
      expect(find.byType(ConverterCard), findsNWidgets(2));
      expect(find.byType(ConverterKeypad), findsOneWidget);
      expectTouchTargets(tester);
    });

    testWidgets('landscape: keypad sits to the right of the cards', (
      tester,
    ) async {
      await pumpConverter(tester, size: phoneLandscape);

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(ConverterKeypad)).left,
        greaterThan(tester.getRect(find.byType(CategoryPicker)).right),
      );
      expectTouchTargets(tester);
    });

    for (final (name, size) in [
      ('phone portrait', phone),
      ('phone landscape', phoneLandscape),
      ('tablet portrait', TestWindows.tabletPortrait),
      ('tablet landscape', TestWindows.tabletLandscape),
    ]) {
      testWidgets('$name fits at 200% text', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpConverter(tester, size: size);

        expect(tester.takeException(), isNull);
        expectTouchTargets(tester);
      });
    }
  });

  group('category and units', () {
    testWidgets('starts on Length, showing m and km', (tester) async {
      await pumpConverter(tester);

      expect(textIn(fromCard(), 'm'), findsOneWidget);
      expect(textIn(toCard(), 'km'), findsOneWidget);
    });

    testWidgets('switching category shows its first two units', (tester) async {
      await pumpConverter(tester);

      await tapVisible(tester, find.text('Weight'));
      await tester.pumpAndSettle();

      expect(textIn(fromCard(), 'kg'), findsOneWidget);
      expect(textIn(toCard(), 'g'), findsOneWidget);
    });
  });

  group('typing and result', () {
    testWidgets('typing digits computes the converted result', (tester) async {
      await pumpConverter(tester);

      await tapVisible(tester, keypadKey('5'));
      await tester.pumpAndSettle();

      expect(textIn(fromCard(), '5'), findsOneWidget);
      expect(textIn(toCard(), '0.005'), findsOneWidget); // 5 m = 0.005 km
    });

    testWidgets('backspace edits the amount', (tester) async {
      await pumpConverter(tester);
      await tapVisible(tester, keypadKey('5'));
      await tapVisible(tester, keypadKey('0'));
      await tester.pumpAndSettle();
      expect(textIn(fromCard(), '50'), findsOneWidget);

      await tapVisible(tester, keypadKey('Backspace'));
      await tester.pumpAndSettle();

      expect(textIn(fromCard(), '5'), findsOneWidget);
    });
  });

  group('swap', () {
    testWidgets('exchanges the units and keeps the typed text', (tester) async {
      await pumpConverter(tester);
      await tapVisible(tester, keypadKey('1'));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byTooltip('Swap units'));
      await tester.pumpAndSettle();

      expect(textIn(fromCard(), 'km'), findsOneWidget);
      expect(textIn(toCard(), 'm'), findsOneWidget);
      expect(textIn(fromCard(), '1'), findsOneWidget);
      expect(textIn(toCard(), '1,000'), findsOneWidget); // 1 km = 1000 m
    });
  });

  group('unit picker', () {
    testWidgets('opens, filters by search and picks a unit', (tester) async {
      await pumpConverter(tester);

      await tapVisible(tester, fromCard());
      await tester.pumpAndSettle();

      expect(find.text('Choose a unit'), findsOneWidget);
      expect(find.text('mile'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'mi');
      await tester.pumpAndSettle();

      expect(find.text('mile'), findsOneWidget);
      expect(find.text('cm'), findsNothing);

      await tapVisible(tester, find.text('mile'));
      await tester.pumpAndSettle();

      expect(textIn(fromCard(), 'mile'), findsOneWidget);
    });

    testWidgets('search with no matches shows the empty message', (
      tester,
    ) async {
      await pumpConverter(tester);

      await tapVisible(tester, fromCard());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No matching units.'), findsOneWidget);
    });

    testWidgets('search also matches unit names, which screen readers hear', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpConverter(tester);

      await tapVisible(tester, fromCard());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'kilo');
      await tester.pumpAndSettle();

      Finder inSheet(String text) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(text),
      );
      expect(inSheet('km'), findsOneWidget);
      expect(inSheet('cm'), findsNothing);
      expect(find.bySemanticsLabel('kilometres'), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('a card reads its amount with the unit name, not the symbol', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpConverter(tester);

    await tapVisible(tester, keypadKey('8'));
    await tapVisible(tester, keypadKey('0'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(fromCard()).label,
      allOf(contains('80 metres'), isNot(contains('\nm\n'))),
    );
    handle.dispose();
  });

  group('temperature sign toggle', () {
    testWidgets('is disabled outside temperature, enabled for it', (
      tester,
    ) async {
      await pumpConverter(tester);
      final signKey = keypadKey('Toggle sign');

      expect(tester.widget<CalculatorButton>(signKey).onPressed, isNull);

      await tapVisible(tester, find.text('Temperature'));
      await tester.pumpAndSettle();

      expect(tester.widget<CalculatorButton>(signKey).onPressed, isNotNull);

      await tapVisible(tester, signKey);
      await tapVisible(tester, keypadKey('4'));
      await tapVisible(tester, keypadKey('0'));
      await tester.pumpAndSettle();

      const negative40 = '${LocalizedNumberFormat.minusSign}40';
      expect(textIn(fromCard(), negative40), findsOneWidget);
      expect(textIn(toCard(), negative40), findsOneWidget); // -40°C = -40°F
    });
  });
}
