import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/core/widgets/key_grid.dart';
import 'package:smart_calculator/features/programmer/application/programmer_notifier.dart';
import 'package:smart_calculator/features/programmer/domain/programmer_session.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The programmer keypad: five columns, six rows.
///
/// ```text
/// A   B   C   AND  OR
/// D   E   F   XOR  NOT
/// 7   8   9   <<   >>
/// 4   5   6   ×    ÷
/// 1   2   3   −    ±
/// AC  0   ⌫   +    =
/// ```
///
/// All sixteen digit keys are always present. A digit that cannot be typed
/// now (not a digit of the base, or the number would no longer fit the word)
/// is disabled, which screen readers announce. Holding ⌫ clears everything.
/// Every press gives a light haptic tick.
class ProgrammerKeypad extends ConsumerWidget {
  /// Creates the keypad, with rows [rowHeight] tall and [gap] between keys.
  const ProgrammerKeypad({
    super.key,
    required this.rowHeight,
    this.gap = AppSpacing.sm,
  });

  /// The height of one key row.
  final double rowHeight;

  /// The space between keys.
  final double gap;

  /// The number of key rows, for sizing the keypad.
  static const int rowCount = 6;

  /// Which of the sixteen digits can be typed now, as a bit mask (bit `d` is
  /// digit `d`), plus bit 16 for `±`. A mask so the keypad rebuilds only when
  /// a key's availability changes, not on every press.
  static int availability(ProgrammerSession session) {
    var mask = session.canNegate ? 1 << 16 : 0;
    for (var digit = 0; digit < 16; digit++) {
      if (session.canAppend(digit)) mask |= 1 << digit;
    }
    return mask;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(programmerProvider.notifier);
    final mask = ref.watch(programmerProvider.select(availability));

    void press(VoidCallback action) {
      HapticFeedback.selectionClick();
      action();
    }

    CalculatorButton digit(int value) {
      final label = value.toRadixString(16).toUpperCase();
      return CalculatorButton(
        kind: CalculatorButtonKind.digit,
        label: label,
        semanticLabel: label,
        onPressed: mask & (1 << value) != 0
            ? () => press(() => notifier.typeDigit(value))
            : null,
      );
    }

    CalculatorButton arithmetic(
      String symbol,
      String semanticLabel,
      ProgrammerOperation operation,
    ) => CalculatorButton(
      kind: CalculatorButtonKind.operator,
      label: symbol,
      semanticLabel: semanticLabel,
      onPressed: () => press(() => notifier.pressOperator(operation)),
    );

    CalculatorButton bitwise(
      String label,
      String semanticLabel,
      ProgrammerOperation operation,
    ) => CalculatorButton(
      kind: CalculatorButtonKind.function,
      label: label,
      semanticLabel: semanticLabel,
      onPressed: () => press(() => notifier.pressOperator(operation)),
    );

    return KeyGrid(
      gap: gap,
      rowHeight: rowHeight,
      rows: [
        [
          digit(0xA),
          digit(0xB),
          digit(0xC),
          bitwise(l10n.programmerKeyAnd, l10n.programmerKeyAndLabel, .and),
          bitwise(l10n.programmerKeyOr, l10n.programmerKeyOrLabel, .or),
        ],
        [
          digit(0xD),
          digit(0xE),
          digit(0xF),
          bitwise(l10n.programmerKeyXor, l10n.programmerKeyXorLabel, .xor),
          CalculatorButton(
            kind: CalculatorButtonKind.function,
            label: l10n.programmerKeyNot,
            semanticLabel: l10n.programmerKeyNotLabel,
            onPressed: () => press(notifier.pressNot),
          ),
        ],
        [
          digit(7),
          digit(8),
          digit(9),
          bitwise(
            l10n.programmerKeyShiftLeft,
            l10n.programmerKeyShiftLeftLabel,
            .shiftLeft,
          ),
          bitwise(
            l10n.programmerKeyShiftRight,
            l10n.programmerKeyShiftRightLabel,
            .shiftRight,
          ),
        ],
        [
          digit(4),
          digit(5),
          digit(6),
          arithmetic('×', l10n.keyMultiplyLabel, .multiply),
          arithmetic('÷', l10n.keyDivideLabel, .divide),
        ],
        [
          digit(1),
          digit(2),
          digit(3),
          arithmetic('−', l10n.keySubtractLabel, .subtract),
          CalculatorButton(
            kind: CalculatorButtonKind.function,
            label: '±',
            semanticLabel: l10n.programmerKeyNegateLabel,
            onPressed: mask & (1 << 16) != 0
                ? () => press(notifier.pressNegate)
                : null,
          ),
        ],
        [
          CalculatorButton(
            kind: CalculatorButtonKind.function,
            label: l10n.keyAllClear,
            semanticLabel: l10n.keyAllClearLabel,
            onPressed: () => press(notifier.clear),
          ),
          digit(0),
          CalculatorButton(
            kind: CalculatorButtonKind.function,
            icon: Icons.backspace_outlined,
            semanticLabel: l10n.keyBackspaceLabel,
            onPressed: () => press(notifier.backspace),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              notifier.clear();
            },
          ),
          arithmetic('+', l10n.keyAddLabel, .add),
          CalculatorButton(
            kind: CalculatorButtonKind.equals,
            label: '=',
            semanticLabel: l10n.keyEqualsLabel,
            onPressed: () => press(notifier.pressEquals),
          ),
        ],
      ],
    );
  }
}
