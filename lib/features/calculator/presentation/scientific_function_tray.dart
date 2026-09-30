import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/calculator/domain/expression_buffer.dart';
import 'package:smart_calculator/features/calculator/domain/scientific_keys.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The scientific function-key tray: every function from
/// [scientificKeyGroups], grouped left to right, in one
/// horizontally-scrollable row. Scrolling (not shrinking keys) is how this
/// fits more keys than a phone is wide — every key stays a real, 48 dp
/// touch target.
///
/// [second] selects each key's 2nd/inverse binding where one exists; a key
/// with none shows and does the same thing either way.
class ScientificFunctionTray extends ConsumerWidget {
  /// Creates the tray.
  const ScientificFunctionTray({super.key, required this.second});

  /// Whether 2nd is active.
  final bool second;

  /// The width given to each key, ample even for the longest label (`x⁻¹`
  /// styled labels, `cosh`).
  static const double _keyWidth = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(calculatorProvider.notifier);

    void press(CalculatorKey key) {
      HapticFeedback.selectionClick();
      notifier.press(key);
    }

    Widget keyButton(ScientificKey key) {
      final active = key.keyFor(second: second);
      final (label, semanticLabel) = _labelsFor(l10n, active);
      return SizedBox(
        width: _keyWidth,
        child: CalculatorButton(
          kind: CalculatorButtonKind.function,
          label: label,
          semanticLabel: semanticLabel,
          onPressed: () => press(active),
        ),
      );
    }

    return SizedBox(
      height: kMinInteractiveDimension,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (groupIndex, group) in scientificKeyGroups.indexed) ...[
              if (groupIndex > 0) const SizedBox(width: AppSpacing.md),
              for (final (keyIndex, key) in group.keys.indexed) ...[
                if (keyIndex > 0) const SizedBox(width: AppSpacing.xs),
                keyButton(key),
              ],
            ],
          ],
        ),
      ),
    );
  }

  (String, String) _labelsFor(AppLocalizations l10n, CalculatorKey key) =>
      switch (key) {
        CalculatorKey.sin => (l10n.keySin, l10n.keySinLabel),
        CalculatorKey.cos => (l10n.keyCos, l10n.keyCosLabel),
        CalculatorKey.tan => (l10n.keyTan, l10n.keyTanLabel),
        CalculatorKey.asin => (l10n.keyAsin, l10n.keyAsinLabel),
        CalculatorKey.acos => (l10n.keyAcos, l10n.keyAcosLabel),
        CalculatorKey.atan => (l10n.keyAtan, l10n.keyAtanLabel),
        CalculatorKey.sinh => (l10n.keySinh, l10n.keySinhLabel),
        CalculatorKey.cosh => (l10n.keyCosh, l10n.keyCoshLabel),
        CalculatorKey.tanh => (l10n.keyTanh, l10n.keyTanhLabel),
        CalculatorKey.log => (l10n.keyLog, l10n.keyLogLabel),
        CalculatorKey.ln => (l10n.keyLn, l10n.keyLnLabel),
        CalculatorKey.power => (CalculatorSymbols.power, l10n.keyPowerLabel),
        CalculatorKey.sqrt => (l10n.keySqrt, l10n.keySqrtLabel),
        CalculatorKey.cbrt => (l10n.keyCbrt, l10n.keyCbrtLabel),
        CalculatorKey.square => (l10n.keySquare, l10n.keySquareLabel),
        CalculatorKey.cube => (l10n.keyCube, l10n.keyCubeLabel),
        CalculatorKey.powerOfTen => (
          l10n.keyPowerOfTen,
          l10n.keyPowerOfTenLabel,
        ),
        CalculatorKey.powerOfE => (l10n.keyPowerOfE, l10n.keyPowerOfELabel),
        CalculatorKey.abs => (l10n.keyAbs, l10n.keyAbsLabel),
        CalculatorKey.factorial => (
          CalculatorSymbols.factorial,
          l10n.keyFactorialLabel,
        ),
        CalculatorKey.pi => (CalculatorSymbols.pi, l10n.keyPiLabel),
        CalculatorKey.euler => (CalculatorSymbols.euler, l10n.keyEulerLabel),
        _ => throw ArgumentError('Not a scientific tray key: $key'),
      };
}
