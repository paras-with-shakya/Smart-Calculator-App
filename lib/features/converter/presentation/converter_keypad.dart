import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/features/converter/application/converter_notifier.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// A compact numeric-only keypad for the converter's typed amount: digits,
/// the decimal point, a sign toggle (only enabled where the category
/// allows a negative amount — temperature) and backspace (held, clears
/// everything, the same convention the main calculator's backspace uses).
///
/// Built directly from [CalculatorButton], not `CalculatorKeypad` — that
/// widget is wired to the main calculator's own notifier and grammar
/// (operators, brackets, percent), none of which a plain typed amount
/// needs.
class ConverterKeypad extends ConsumerWidget {
  /// Creates the keypad, with [gap] between keys.
  const ConverterKeypad({super.key, this.gap = AppSpacing.sm});

  /// The space between keys.
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(converterProvider.notifier);
    final allowsNegative = ref.watch(
      converterProvider.select((state) => state.table.allowsNegative),
    );

    void press(VoidCallback action) {
      ref.read(keyFeedbackProvider).key();
      action();
    }

    CalculatorButton digit(int value) => CalculatorButton(
      kind: CalculatorButtonKind.digit,
      label: '$value',
      semanticLabel: '$value',
      onPressed: () => press(() => notifier.typeDigit('$value')),
    );

    final rows = <List<Widget>>[
      [
        digit(7),
        digit(8),
        digit(9),
        CalculatorButton(
          kind: CalculatorButtonKind.function,
          icon: Icons.backspace_outlined,
          semanticLabel: l10n.keyBackspaceLabel,
          longPressHint: l10n.keyBackspaceLongPressHint,
          onPressed: () => press(notifier.backspace),
          onLongPress: () {
            ref.read(keyFeedbackProvider).heavy();
            notifier.clear();
          },
        ),
      ],
      [
        digit(4),
        digit(5),
        digit(6),
        CalculatorButton(
          kind: CalculatorButtonKind.function,
          label: '±',
          semanticLabel: l10n.keyToggleSignLabel,
          onPressed: allowsNegative ? () => press(notifier.toggleSign) : null,
        ),
      ],
      [digit(1), digit(2), digit(3), const SizedBox.shrink()],
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
        SizedBox(height: gap),
        Expanded(
          child: Row(
            crossAxisAlignment: .stretch,
            children: [
              const Spacer(),
              SizedBox(width: gap),
              Expanded(flex: 2, child: digit(0)),
              SizedBox(width: gap),
              Expanded(
                child: CalculatorButton(
                  kind: CalculatorButtonKind.digit,
                  label: '.',
                  semanticLabel: l10n.keyDecimalPointLabel,
                  onPressed: () => press(notifier.typeDecimalPoint),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
