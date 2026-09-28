import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/application/memory_notifier.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The memory row: MC, MR, M+, M−, MS.
///
/// It is always visible, rather than hidden in a menu, so memory is one
/// tap away. MC and MR need a value in memory; M+, M− and MS need a value
/// on the display. Keys that can't act are disabled.
class CalculatorMemoryKeys extends ConsumerWidget {
  /// Creates the memory row.
  const CalculatorMemoryKeys({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasMemory = ref.watch(memoryProvider.select((m) => m != null));
    final hasValue = ref.watch(
      calculatorProvider.select((state) => state.currentValue != null),
    );
    final notifier = ref.read(calculatorProvider.notifier);

    VoidCallback? action(bool enabled, FutureOr<void> Function() run) => enabled
        ? () {
            HapticFeedback.selectionClick();
            unawaited(Future.sync(run));
          }
        : null;

    final keys = [
      (
        l10n.memoryClear,
        l10n.memoryClearLabel,
        action(hasMemory, notifier.memoryClear),
      ),
      (
        l10n.memoryRecall,
        l10n.memoryRecallLabel,
        action(hasMemory, notifier.memoryRecall),
      ),
      (
        l10n.memoryAdd,
        l10n.memoryAddLabel,
        action(hasValue, notifier.memoryAdd),
      ),
      (
        l10n.memorySubtract,
        l10n.memorySubtractLabel,
        action(hasValue, notifier.memorySubtract),
      ),
      (
        l10n.memoryStore,
        l10n.memoryStoreLabel,
        action(hasValue, notifier.memoryStore),
      ),
    ];

    return SizedBox(
      height: kMinInteractiveDimension,
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          for (final (index, (label, semanticLabel, onPressed))
              in keys.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: CalculatorButton(
                kind: CalculatorButtonKind.memory,
                label: label,
                semanticLabel: semanticLabel,
                onPressed: onPressed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
