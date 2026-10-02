import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/core/widgets/display_text.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/application/memory_notifier.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_display.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_keypad.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_view.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/touch_targets.dart';

/// The user's phone, 360 x 800 dp, in portrait and landscape.
const Size phone = Size(360, 800);
const Size phoneLandscape = Size(800, 360);

Finder key(String semanticLabel) => find.byWidgetPredicate(
  (widget) =>
      widget is CalculatorButton && widget.semanticLabel == semanticLabel,
);

/// The display line showing [text], ignoring the zero-width spaces where
/// lines may break.
Finder displayLine(String text) => find.byWidgetPredicate(
  (widget) => widget is DisplayText && widget.text.replaceAll('​', '') == text,
);

void main() {
  setUp(useInMemoryPreferences);

  /// Starts the app in a region, the way the phone's settings would.
  Future<void> pumpCalculator(
    WidgetTester tester, {
    Size size = phone,
    Locale locale = const Locale('en', 'US'),
  }) async {
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await pumpApp(tester, size: size);
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CalculatorView)));

  CalculatorState stateOf(WidgetTester tester) =>
      containerOf(tester).read(calculatorProvider);

  Future<void> tapKeys(WidgetTester tester, List<String> labels) async {
    for (final label in labels) {
      await tester.tap(key(label));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, String label) =>
      tester.widget<CalculatorButton>(key(label)).onPressed != null;

  group('keypad', () {
    testWidgets('has every basic key, announced by name', (tester) async {
      await pumpCalculator(tester);

      for (final label in [
        l10n.keyAllClearLabel,
        l10n.keyBracketsLabel,
        l10n.keyPercentLabel,
        l10n.keyDivideLabel,
        l10n.keyMultiplyLabel,
        l10n.keySubtractLabel,
        l10n.keyAddLabel,
        l10n.keyEqualsLabel,
        l10n.keyDecimalPointLabel,
        l10n.keyBackspaceLabel,
        for (var digit = 0; digit <= 9; digit++) '$digit',
      ]) {
        expect(key(label), findsOneWidget, reason: label);
        expect(
          tester.getSemantics(key(label)),
          isSemantics(label: label, isButton: true, isEnabled: true),
          reason: label,
        );
      }
      expect(find.byType(CalculatorButton), findsNWidgets(20 + 5));
    });

    testWidgets('keys are laid out as the basic keypad', (tester) async {
      await pumpCalculator(tester);

      Offset at(String label) => tester.getCenter(key(label));
      // Row by row, left to right.
      final rows = [
        [l10n.keyAllClearLabel, l10n.keyBracketsLabel, l10n.keyPercentLabel],
        ['7', '8', '9', l10n.keyMultiplyLabel],
        ['4', '5', '6', l10n.keySubtractLabel],
        ['1', '2', '3', l10n.keyAddLabel],
        ['0', l10n.keyDecimalPointLabel, l10n.keyBackspaceLabel],
      ];
      for (final row in rows) {
        for (var i = 1; i < row.length; i++) {
          expect(at(row[i]).dy, closeTo(at(row[0]).dy, 0.5), reason: row[i]);
          expect(at(row[i]).dx, greaterThan(at(row[i - 1]).dx), reason: row[i]);
        }
      }
      expect(at('7').dy, greaterThan(at(l10n.keyAllClearLabel).dy));
      expect(at('0').dy, greaterThan(at('1').dy));
      expect(
        at(l10n.keyEqualsLabel).dx,
        greaterThan(at(l10n.keyBackspaceLabel).dx),
      );
    });

    testWidgets('each press gives a haptic tick', (tester) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpCalculator(tester);

      await tapKeys(tester, ['7', l10n.keyAddLabel]);

      expect(haptics, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
    });
  });

  group('display', () {
    testWidgets('shows a muted 0 before anything is typed', (tester) async {
      await pumpCalculator(tester);

      expect(displayLine('0'), findsOneWidget);
    });

    testWidgets('shows the expression and its live preview', (tester) async {
      await pumpCalculator(tester);

      await tapKeys(tester, ['1', '2', l10n.keyAddLabel, '3']);

      expect(displayLine('12+3'), findsOneWidget);
      expect(displayLine('15'), findsOneWidget);
      expect(
        tester.getSemantics(displayLine('12+3')),
        isSemantics(label: '12 ${l10n.spokenPlus} 3'),
      );
      expect(
        tester.getSemantics(displayLine('15')),
        isSemantics(label: l10n.displayPreviewLabel('15')),
      );
    });

    testWidgets('= shows the result below the expression it came from', (
      tester,
    ) async {
      await pumpCalculator(tester);

      await tapKeys(tester, [
        '1',
        '2',
        l10n.keyAddLabel,
        '3',
        l10n.keyEqualsLabel,
      ]);

      final result = displayLine('15');
      final expression = displayLine('12+3');
      expect(result, findsOneWidget);
      expect(expression, findsOneWidget);
      expect(
        tester.getRect(expression).bottom,
        lessThanOrEqualTo(tester.getRect(result).top),
      );
      expect(
        tester.getSemantics(result),
        isSemantics(label: l10n.displayResultLabel('15'), isLiveRegion: true),
      );
    });

    testWidgets('an error shows its message and keeps the expression', (
      tester,
    ) async {
      await pumpCalculator(tester);

      await tapKeys(tester, [
        '5',
        l10n.keyDivideLabel,
        '0',
        l10n.keyEqualsLabel,
      ]);

      expect(displayLine('5÷0'), findsOneWidget);
      expect(displayLine(l10n.errorDivisionByZero), findsOneWidget);

      await tapKeys(tester, [l10n.keyBackspaceLabel, '2']);

      expect(displayLine(l10n.errorDivisionByZero), findsNothing);
      expect(displayLine('5÷2'), findsOneWidget);
      expect(displayLine('2.5'), findsOneWidget);
    });

    testWidgets('tapping the expression moves the cursor there', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await tapKeys(tester, ['1', '2', '3']);

      final line = tester.getRect(displayLine('123'));
      // The test font's glyphs are as wide as the font size (48 px), and
      // the line is end-aligned: "123" spans its last 144 px.
      await tester.tapAt(Offset(line.right - 140, line.center.dy));
      await tester.pump();

      expect(stateOf(tester).buffer.cursor, 0);

      await tapKeys(tester, ['9']);
      expect(displayLine('9,123'), findsOneWidget);
    });

    testWidgets('holding backspace clears everything', (tester) async {
      await pumpCalculator(tester);
      await tapKeys(tester, ['1', l10n.keyAddLabel, '2']);

      await tester.longPress(key(l10n.keyBackspaceLabel));
      await tester.pumpAndSettle();

      expect(stateOf(tester), const CalculatorState());
      expect(displayLine('0'), findsOneWidget);
    });

    testWidgets('an India-region phone groups by lakh and crore', (
      tester,
    ) async {
      await pumpCalculator(tester, locale: const Locale('en', 'IN'));

      await tapKeys(tester, ['1', '2', '3', '4', '5', '6', '7']);

      expect(displayLine('12,34,567'), findsOneWidget);
    });

    testWidgets('a comma-decimal region shows a comma on the decimal key', (
      tester,
    ) async {
      await pumpCalculator(tester, locale: const Locale('de', 'DE'));

      expect(
        tester.widget<CalculatorButton>(key(l10n.keyDecimalPointLabel)).label,
        ',',
      );

      await tapKeys(tester, [
        '1',
        '2',
        '3',
        '4',
        l10n.keyDecimalPointLabel,
        '5',
      ]);

      expect(displayLine('1.234,5'), findsOneWidget);
    });
  });

  group('memory row', () {
    testWidgets('starts with every key disabled', (tester) async {
      await pumpCalculator(tester);

      for (final label in [
        l10n.memoryClearLabel,
        l10n.memoryRecallLabel,
        l10n.memoryAddLabel,
        l10n.memorySubtractLabel,
        l10n.memoryStoreLabel,
      ]) {
        expect(isEnabled(tester, label), isFalse, reason: label);
      }
    });

    testWidgets('stores, shows, recalls and clears the memory', (tester) async {
      await pumpCalculator(tester);
      await tapKeys(tester, ['4', '2']);
      expect(isEnabled(tester, l10n.memoryStoreLabel), isTrue);
      expect(isEnabled(tester, l10n.memoryRecallLabel), isFalse);

      await tapKeys(tester, [l10n.memoryStoreLabel]);

      expect(containerOf(tester).read(memoryProvider), isNotNull);
      final badge = find.bySemanticsLabel(l10n.memoryIndicatorLabel('42'));
      expect(badge, findsOneWidget);
      // Its own small node, not a label on the whole screen (device test).
      expect(
        tester.getSemantics(badge).rect.height,
        lessThan(kMinInteractiveDimension),
      );
      expect(isEnabled(tester, l10n.memoryRecallLabel), isTrue);

      await tapKeys(tester, [
        l10n.keyAllClearLabel,
        '2',
        l10n.memoryRecallLabel,
      ]);
      expect(displayLine('2×42'), findsOneWidget);

      await tapKeys(tester, [l10n.memoryClearLabel]);
      expect(containerOf(tester).read(memoryProvider), isNull);
      expect(
        find.bySemanticsLabel(l10n.memoryIndicatorLabel('42')),
        findsNothing,
      );
    });
  });

  group('keyboard', () {
    testWidgets('types, evaluates and edits', (tester) async {
      await pumpCalculator(tester);

      for (final keyboardKey in [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
      ]) {
        await tester.sendKeyEvent(keyboardKey);
      }
      await tester.sendKeyEvent(
        LogicalKeyboardKey.numpadMultiply,
        character: '*',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();
      expect(displayLine('12×3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(stateOf(tester).result, isNotNull);
      expect(displayLine('36'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(stateOf(tester), const CalculatorState());
    });

    testWidgets('backspace, arrows, Home and End edit at the cursor', (
      tester,
    ) async {
      await pumpCalculator(tester);
      for (final keyboardKey in [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.backspace,
      ]) {
        await tester.sendKeyEvent(keyboardKey);
      }
      await tester.pumpAndSettle();
      expect(displayLine('13'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(
        LogicalKeyboardKey.numpadSubtract,
        character: '-',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pumpAndSettle();
      expect(displayLine('−134'), findsOneWidget);
    });

    testWidgets('Ctrl+V pastes a number written the region way', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData'
            ? <String, Object?>{'text': '12,34,567.5'}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpCalculator(tester, locale: const Locale('en', 'IN'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(displayLine('12,34,567.5'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('portrait: the keypad is below the display', (tester) async {
      await pumpCalculator(tester);

      expect(
        tester.getRect(find.byType(CalculatorKeypad)).top,
        greaterThan(tester.getRect(find.byType(CalculatorDisplay)).bottom),
      );
      final keypad = tester.getSize(find.byType(CalculatorKeypad));
      expect(keypad.height, lessThanOrEqualTo(keypad.width * 1.3));
      expectTouchTargets(tester);
    });

    testWidgets('landscape: the keypad is beside the display', (tester) async {
      await pumpCalculator(tester, size: phoneLandscape);

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(CalculatorKeypad)).left,
        greaterThan(tester.getRect(find.byType(CalculatorDisplay)).right),
      );
      expectTouchTargets(tester);
    });

    // Regression: on the user's phone in landscape, the 34 dp status bar left
    // keys 47.6 dp tall (device test, 2026-09-28).
    testWidgets('landscape under a status bar keeps 48 dp keys', (
      tester,
    ) async {
      tester.view
        ..padding = const FakeViewPadding(top: 34)
        ..viewPadding = const FakeViewPadding(top: 34);
      await pumpCalculator(tester, size: phoneLandscape);

      expect(tester.takeException(), isNull);
      expectTouchTargets(tester);
    });

    for (final (name, size) in [
      ('phone portrait', phone),
      ('phone landscape', phoneLandscape),
      ('tablet portrait', TestWindows.tabletPortrait),
      ('tablet landscape', TestWindows.tabletLandscape),
    ]) {
      testWidgets('$name fits at 200% text, with a long expression', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpCalculator(tester, size: size);

        containerOf(tester)
            .read(calculatorProvider.notifier)
            .typeText('123456789012345×987654321098765+${'9+' * 20}1');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the keypad is never wider than its maximum', (tester) async {
      await pumpCalculator(tester, size: TestWindows.tabletPortrait);

      expect(
        tester.getSize(find.byType(CalculatorKeypad)).width,
        CalculatorView.keypadMaxWidth,
      );
    });
  });
}
