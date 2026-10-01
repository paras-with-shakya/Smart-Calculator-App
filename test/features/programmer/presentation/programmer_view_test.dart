import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/core/widgets/display_text.dart';
import 'package:smart_calculator/features/programmer/application/programmer_notifier.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_view.dart';

import '../../../helpers/test_app.dart';

const Size phone = Size(360, 800);
const Size smallPhone = Size(320, 640);
const Size phoneLandscape = Size(800, 360);

CalculatorButton keyWithLabel(WidgetTester tester, String label) =>
    tester.widget<CalculatorButton>(
      find.byWidgetPredicate(
        (widget) => widget is CalculatorButton && widget.label == label,
      ),
    );

Finder key(String label) => find.byWidgetPredicate(
  (widget) => widget is CalculatorButton && widget.label == label,
);

Finder readout(String text) => find.byWidgetPredicate(
  (widget) => widget is DisplayText && widget.text == text,
);

void main() {
  setUp(useInMemoryPreferences);

  late ProviderContainer container;

  Future<void> pumpProgrammer(WidgetTester tester, {Size size = phone}) async {
    await pumpApp(tester, size: size);
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container
        .read(currentModeProvider.notifier)
        .select(CalculatorMode.programmer);
    await tester.pumpAndSettle();
  }

  Future<void> tapKeys(WidgetTester tester, List<String> labels) async {
    for (final label in labels) {
      final finder = key(label);
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> chooseFromSheet(
    WidgetTester tester, {
    required String button,
    required String option,
  }) async {
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(option),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('shows the controls, four base rows and thirty keys', (
      tester,
    ) async {
      await pumpProgrammer(tester);

      expect(find.byType(ProgrammerView), findsOneWidget);
      expect(find.text(l10n.programmerWordSizeButton(32)), findsOneWidget);
      expect(find.text(l10n.programmerSigned), findsOneWidget);
      for (final label in [
        l10n.programmerBaseHex,
        l10n.programmerBaseDec,
        l10n.programmerBaseOct,
        l10n.programmerBaseBin,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(CalculatorButton), findsNWidgets(30));
      expect(tester.takeException(), isNull);
    });

    testWidgets('starts at zero in decimal, 32-bit signed', (tester) async {
      await pumpProgrammer(tester);

      final session = container.read(programmerProvider);
      expect(session.base, ProgrammerBase.decimal);
      expect(session.word, const ProgrammerWord(bits: 32, signed: true));
      expect(readout('0'), findsNWidgets(3)); // HEX, DEC, OCT
      expect(readout('0000 0000 0000 0000'), findsNWidgets(2)); // two BIN lines
    });

    for (final (name, size) in [
      ('phone', phone),
      ('small phone', smallPhone),
      ('landscape', phoneLandscape),
    ]) {
      testWidgets('$name: no overflow and every key is a 48 dp target', (
        tester,
      ) async {
        await pumpProgrammer(tester, size: size);

        expect(tester.takeException(), isNull);
        for (final element in find.byType(CalculatorButton).evaluate()) {
          final box = element.renderObject! as RenderBox;
          expect(box.size.height, greaterThanOrEqualTo(48));
          expect(box.size.width, greaterThanOrEqualTo(48));
        }
      });
    }

    testWidgets('200% text: no overflow, every key still a 48 dp target', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpProgrammer(tester);
      container.read(programmerProvider.notifier).setBits(64);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final element in find.byType(CalculatorButton).evaluate()) {
        final box = element.renderObject! as RenderBox;
        expect(box.size.height, greaterThanOrEqualTo(48));
        expect(box.size.width, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('200% text: no label is broken inside a word', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpProgrammer(tester);
      container.read(programmerProvider.notifier).setBits(8);
      await tester.pumpAndSettle();

      // A label that fits on one line is as tall as a one-line label.
      for (final label in [
        l10n.programmerBaseHex,
        l10n.programmerBaseDec,
        l10n.programmerBaseOct,
        l10n.programmerBaseBin,
        l10n.programmerSigned,
        l10n.programmerWordSizeButton(8),
      ]) {
        final size = tester.getSize(find.text(label));
        expect(size.height, lessThan(2 * 14 * 1.5 * 2), reason: label);
      }
      final hex = tester.getSize(find.text(l10n.programmerBaseHex));
      final bin = tester.getSize(find.text(l10n.programmerBaseBin));
      expect(hex.height, bin.height); // same single line
    });

    testWidgets('200% text in landscape does not overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpProgrammer(tester, size: phoneLandscape);
      container.read(programmerProvider.notifier).setBits(64);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the keypad stays put while typing, even at 64 bits', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      container.read(programmerProvider.notifier).setBits(64);
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(key('7'));

      await tapKeys(tester, ['5', '−', '9', '=']); // 5 - 9 = -4
      await tapKeys(tester, ['±']);

      expect(tester.getTopLeft(key('7')), before);
      expect(tester.takeException(), isNull);
    });

    testWidgets('64 bits fits a 800 dp phone once its status bar is counted', (
      tester,
    ) async {
      // A real 360x800 dp phone gives the page about 710 dp: its status bar
      // and the shell header come off the top. The test window has no status
      // bar, so shrink it by the same amount.
      await pumpProgrammer(tester, size: const Size(360, 766));
      container.read(programmerProvider.notifier).setBits(64);
      await tester.pumpAndSettle();

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.maxScrollExtent, 0);
    });

    testWidgets('the 64-bit readout needs no more than the phone has', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      container.read(programmerProvider.notifier).setBits(64);
      await tester.pumpAndSettle();

      // The `=` key (last row) is on screen without scrolling.
      final equals = tester.getRect(key('='));
      expect(equals.bottom, lessThanOrEqualTo(800));
    });
  });

  group('typing and conversion', () {
    testWidgets('a decimal number shows in every base', (tester) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['2', '5', '5']);

      expect(readout('FF'), findsOneWidget);
      expect(readout('255'), findsOneWidget);
      expect(readout('377'), findsOneWidget);
      expect(readout('0000 0000 1111 1111'), findsOneWidget);
    });

    testWidgets('a negative signed number: pattern in hex/bin, value in dec', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['5', '±']);

      expect(readout('−5'), findsOneWidget);
      expect(readout('FFFF FFFB'), findsOneWidget);
      expect(readout('37 777 777 773'), findsOneWidget);
      expect(readout('1111 1111 1111 1011'), findsOneWidget);
    });

    testWidgets('tapping a row switches the base and keeps the value', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['2', '5', '5']);

      await tester.tap(readout('FF'));
      await tester.pumpAndSettle();
      expect(
        container.read(programmerProvider).base,
        ProgrammerBase.hexadecimal,
      );
      expect(readout('255'), findsOneWidget);

      await tapKeys(tester, ['A']);
      expect(readout('A'), findsOneWidget);
      expect(readout('10'), findsOneWidget);
    });

    testWidgets('keys that cannot be typed are disabled', (tester) async {
      await pumpProgrammer(tester);
      // Decimal: the hex letters are disabled, the digits are not.
      for (final letter in ['A', 'B', 'C', 'D', 'E', 'F']) {
        expect(keyWithLabel(tester, letter).onPressed, isNull, reason: letter);
      }
      for (var d = 0; d <= 9; d++) {
        expect(keyWithLabel(tester, '$d').onPressed, isNotNull, reason: '$d');
      }

      container
          .read(programmerProvider.notifier)
          .setBase(ProgrammerBase.binary);
      await tester.pumpAndSettle();
      expect(keyWithLabel(tester, '0').onPressed, isNotNull);
      expect(keyWithLabel(tester, '1').onPressed, isNotNull);
      for (var d = 2; d <= 9; d++) {
        expect(keyWithLabel(tester, '$d').onPressed, isNull, reason: '$d');
      }

      container.read(programmerProvider.notifier).setBase(ProgrammerBase.octal);
      await tester.pumpAndSettle();
      expect(keyWithLabel(tester, '7').onPressed, isNotNull);
      expect(keyWithLabel(tester, '8').onPressed, isNull);

      container
          .read(programmerProvider.notifier)
          .setBase(ProgrammerBase.hexadecimal);
      await tester.pumpAndSettle();
      for (final label in ['A', 'F', '9', '0']) {
        expect(keyWithLabel(tester, label).onPressed, isNotNull);
      }
    });

    testWidgets('a disabled digit is announced as disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpProgrammer(tester);

      expect(
        tester.getSemantics(key('A')),
        isSemantics(label: 'A', isButton: true, isEnabled: false),
      );
      expect(
        tester.getSemantics(key('7')),
        isSemantics(label: '7', isButton: true, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets('digits run out when the number would not fit', (tester) async {
      await pumpProgrammer(tester);
      container.read(programmerProvider.notifier).setBits(8);
      await tester.pumpAndSettle();

      await tapKeys(tester, ['1', '3']); // 13: a third digit would pass 127
      for (var d = 0; d <= 9; d++) {
        expect(keyWithLabel(tester, '$d').onPressed, isNull, reason: '$d');
      }
    });

    testWidgets('backspace and AC', (tester) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['1', '2', '3']);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is CalculatorButton && w.icon == Icons.backspace_outlined,
        ),
      );
      await tester.pumpAndSettle();
      expect(readout('12'), findsOneWidget);

      await tapKeys(tester, ['AC']);
      expect(readout('0'), findsNWidgets(3));
    });

    testWidgets('holding backspace clears everything', (tester) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['9', '+', '9']);
      await tester.longPress(
        find.byWidgetPredicate(
          (w) => w is CalculatorButton && w.icon == Icons.backspace_outlined,
        ),
      );
      await tester.pumpAndSettle();

      final session = container.read(programmerProvider);
      expect(session.current, BigInt.zero);
      expect(session.pending, isNull);
    });
  });

  group('operations', () {
    testWidgets('0xFF AND 0x0F = 15, typed in hexadecimal', (tester) async {
      await pumpProgrammer(tester);
      container
          .read(programmerProvider.notifier)
          .setBase(ProgrammerBase.hexadecimal);
      await tester.pumpAndSettle();

      await tapKeys(tester, ['F', 'F', 'AND', '0', 'F', '=']);

      expect(readout('F'), findsOneWidget);
      expect(readout('15'), findsOneWidget);
      expect(readout('17'), findsOneWidget);
      expect(readout('0000 0000 0000 0000'), findsOneWidget);
      expect(readout('0000 0000 0000 1111'), findsOneWidget);
    });

    testWidgets('OR, XOR and NOT', (tester) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['1', '2', 'OR', '3', '=']); // 12 | 3 = 15
      expect(readout('15'), findsOneWidget);
      await tapKeys(tester, ['XOR', '5', '=']); // 15 ^ 5 = 10
      expect(readout('10'), findsOneWidget);
      await tapKeys(tester, ['NOT']); // ~10 = -11
      expect(readout('−11'), findsOneWidget);
      expect(readout('FFFF FFF5'), findsOneWidget);
    });

    testWidgets('shifts', (tester) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['1', '<<', '4', '=']);
      expect(readout('16'), findsOneWidget);
      await tapKeys(tester, ['>>', '2', '=']);
      expect(readout('4'), findsNWidgets(3)); // HEX, DEC and OCT alike
    });

    testWidgets('arithmetic runs left to right', (tester) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['2', '+', '3', '×', '4', '=']);
      expect(readout('20'), findsOneWidget);
    });

    testWidgets('division truncates, and by zero shows the error', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['7', '÷', '2', '=']);
      expect(readout('3'), findsWidgets);

      await tapKeys(tester, ['÷', '0', '=']);
      expect(find.text(l10n.errorDivisionByZero), findsOneWidget);
      await tapKeys(tester, ['5']);
      expect(find.text(l10n.errorDivisionByZero), findsNothing);
    });

    testWidgets('the pending operation is shown in the base being typed', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      container
          .read(programmerProvider.notifier)
          .setBase(ProgrammerBase.hexadecimal);
      await tester.pumpAndSettle();
      await tapKeys(tester, ['F', 'F', 'AND']);

      expect(find.text('FF AND'), findsOneWidget);
    });
  });

  group('word size and signedness', () {
    testWidgets('the word-size sheet changes the size', (tester) async {
      await pumpProgrammer(tester);
      await chooseFromSheet(
        tester,
        button: l10n.programmerWordSizeButton(32),
        option: '8',
      );

      expect(find.text(l10n.programmerWordSizeButton(8)), findsOneWidget);
      expect(container.read(programmerProvider).word.bits, 8);
      expect(readout('0000 0000'), findsOneWidget); // one BIN line of 8 bits
    });

    testWidgets('127 + 1 in a signed byte wraps and says so', (tester) async {
      await pumpProgrammer(tester);
      await chooseFromSheet(
        tester,
        button: l10n.programmerWordSizeButton(32),
        option: '8',
      );

      await tapKeys(tester, ['1', '2', '7', '+', '1', '=']);

      expect(readout('−128'), findsOneWidget);
      expect(readout('80'), findsOneWidget);
      expect(find.text(l10n.programmerOverflowNotice(8)), findsOneWidget);

      await tapKeys(tester, ['AC']);
      expect(find.text(l10n.programmerOverflowNotice(8)), findsNothing);
    });

    testWidgets('unsigned: 255 + 1 wraps to 0, and ± is disabled', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      await chooseFromSheet(
        tester,
        button: l10n.programmerWordSizeButton(32),
        option: '8',
      );
      await chooseFromSheet(
        tester,
        button: l10n.programmerSigned,
        option: l10n.programmerUnsigned,
      );

      expect(find.text(l10n.programmerUnsigned), findsOneWidget);
      expect(keyWithLabel(tester, '±').onPressed, isNull);
      await tapKeys(tester, ['2', '5', '5', '+', '1', '=']);

      expect(readout('0'), findsNWidgets(3));
      expect(find.text(l10n.programmerOverflowNotice(8)), findsOneWidget);
    });

    testWidgets('signedness only changes how the bits read', (tester) async {
      await pumpProgrammer(tester);
      container
          .read(programmerProvider.notifier)
          .setBase(ProgrammerBase.hexadecimal);
      await tester.pumpAndSettle();
      await chooseFromSheet(
        tester,
        button: l10n.programmerWordSizeButton(32),
        option: '8',
      );
      await tapKeys(tester, ['F', 'F']);
      expect(readout('−1'), findsOneWidget);

      await chooseFromSheet(
        tester,
        button: l10n.programmerSigned,
        option: l10n.programmerUnsigned,
      );
      expect(readout('255'), findsOneWidget);
      expect(readout('FF'), findsOneWidget);
    });

    testWidgets('the sheets have headings and the current choice', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      await tester.tap(find.text(l10n.programmerWordSizeButton(32)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.programmerWordSizeTitle), findsOneWidget);
      for (final size in ['8', '16', '32', '64']) {
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(size),
          ),
          findsOneWidget,
        );
      }
    });
  });

  group('accessibility', () {
    testWidgets('each base row is one selected-or-not button with its value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpProgrammer(tester);
      await tapKeys(tester, ['2', '5', '5']);

      expect(
        find.bySemanticsLabel(
          l10n.programmerBaseRowSemantics(l10n.programmerBaseNameDec, '255'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          l10n.programmerBaseRowSemantics(l10n.programmerBaseNameHex, 'F F'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('^${l10n.programmerBaseNameBin}, (0 ){24}1 1 1 1 1 1 1 1\$'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the active base row is announced as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpProgrammer(tester);

      final active = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^${l10n.programmerBaseNameDec}, ')),
      );
      expect(active, isSemantics(isSelected: true, isButton: true));
      final other = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^${l10n.programmerBaseNameHex}, ')),
      );
      expect(other, isSemantics(isSelected: false, isButton: true));
      handle.dispose();
    });

    testWidgets('the word controls announce what they set', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpProgrammer(tester);

      expect(
        find.bySemanticsLabel(l10n.programmerWordSizeSemantics(32)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          l10n.programmerSignednessSemantics(l10n.programmerSigned),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('operators are spoken in full', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpProgrammer(tester);

      for (final label in [
        l10n.programmerKeyAndLabel,
        l10n.programmerKeyOrLabel,
        l10n.programmerKeyXorLabel,
        l10n.programmerKeyNotLabel,
        l10n.programmerKeyShiftLeftLabel,
        l10n.programmerKeyShiftRightLabel,
        l10n.programmerKeyNegateLabel,
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      handle.dispose();
    });
  });

  group('rotation (Known Issue #17)', () {
    testWidgets('the calculation survives a change of window shape', (
      tester,
    ) async {
      await pumpProgrammer(tester);
      await tapKeys(tester, ['1', '2', '+', '3']);
      container.read(programmerProvider.notifier).setBits(16);
      await tester.pumpAndSettle();

      tester.view.physicalSize = phoneLandscape;
      await tester.pumpAndSettle();

      expect(find.byType(ProgrammerView), findsOneWidget);
      final session = container.read(programmerProvider);
      expect(session.word.bits, 16);
      expect(session.pending, isNotNull);
      expect(readout('3'), findsWidgets);
      expect(find.text(l10n.programmerWordSizeButton(16)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
