import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/calculator/domain/expression_buffer.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The basic keypad: four columns, five rows, filling the space it is
/// given.
///
/// ```text
/// AC  ( )  %  ÷
/// 7   8    9  ×
/// 4   5    6  −
/// 1   2    3  +
/// 0   .    ⌫  =
/// ```
///
/// The decimal key shows the region's separator. Holding ⌫ clears
/// everything. Every press gives a light haptic tick.
class CalculatorKeypad extends ConsumerWidget {
  /// Creates the keypad, with [gap] between keys.
  const CalculatorKeypad({super.key, this.gap = AppSpacing.sm});

  /// The space between keys.
  final double gap;

  /// The number of key rows, for sizing the keypad.
  static const int rowCount = 5;

  /// The number of key columns, for sizing the keypad.
  static const int columnCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final decimalSeparator = ref.watch(numberFormatProvider).decimalSeparator;
    final notifier = ref.read(calculatorProvider.notifier);

    void press(CalculatorKey key) {
      ref.read(keyFeedbackProvider).key();
      notifier.press(key);
    }

    CalculatorButton digit(int value) => CalculatorButton(
      kind: CalculatorButtonKind.digit,
      label: '$value',
      semanticLabel: '$value',
      onPressed: () => press(CalculatorKey.digit(value)),
    );

    CalculatorButton operator(
      String symbol,
      String semanticLabel,
      CalculatorKey key,
    ) => CalculatorButton(
      kind: CalculatorButtonKind.operator,
      label: symbol,
      semanticLabel: semanticLabel,
      onPressed: () => press(key),
    );

    CalculatorButton function(
      String label,
      String semanticLabel,
      CalculatorKey key,
    ) => CalculatorButton(
      kind: CalculatorButtonKind.function,
      label: label,
      semanticLabel: semanticLabel,
      onPressed: () => press(key),
    );

    final rows = <List<Widget>>[
      [
        function(
          l10n.keyAllClear,
          l10n.keyAllClearLabel,
          CalculatorKey.allClear,
        ),
        function(
          l10n.keyBrackets,
          l10n.keyBracketsLabel,
          CalculatorKey.brackets,
        ),
        function(
          CalculatorSymbols.percent,
          l10n.keyPercentLabel,
          CalculatorKey.percent,
        ),
        operator(
          CalculatorSymbols.divide,
          l10n.keyDivideLabel,
          CalculatorKey.divide,
        ),
      ],
      [
        digit(7),
        digit(8),
        digit(9),
        operator(
          CalculatorSymbols.times,
          l10n.keyMultiplyLabel,
          CalculatorKey.multiply,
        ),
      ],
      [
        digit(4),
        digit(5),
        digit(6),
        operator(
          CalculatorSymbols.minus,
          l10n.keySubtractLabel,
          CalculatorKey.subtract,
        ),
      ],
      [
        digit(1),
        digit(2),
        digit(3),
        operator(CalculatorSymbols.plus, l10n.keyAddLabel, CalculatorKey.add),
      ],
      [
        digit(0),
        CalculatorButton(
          kind: CalculatorButtonKind.digit,
          label: decimalSeparator,
          semanticLabel: l10n.keyDecimalPointLabel,
          onPressed: () => press(CalculatorKey.decimalPoint),
        ),
        CalculatorButton(
          kind: CalculatorButtonKind.function,
          icon: Icons.backspace_outlined,
          semanticLabel: l10n.keyBackspaceLabel,
          onPressed: () => press(CalculatorKey.backspace),
          onLongPress: () {
            ref.read(keyFeedbackProvider).heavy();
            notifier.press(CalculatorKey.allClear);
          },
        ),
        CalculatorButton(
          kind: CalculatorButtonKind.equals,
          label: '=',
          semanticLabel: l10n.keyEqualsLabel,
          onPressed: () => press(CalculatorKey.equals),
        ),
      ],
    ];

    return Column(
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: .stretch,
              children: [
                for (final (column, key) in row.indexed) ...[
                  if (column > 0) SizedBox(width: gap),
                  Expanded(child: key),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
