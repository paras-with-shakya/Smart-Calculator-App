import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/features/programmer/application/programmer_notifier.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_formatting.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// One line under the word controls: the operation waiting for its right
/// operand (`FF AND`), an error, or the overflow notice.
///
/// It always reserves its height, so nothing below it moves when the text
/// appears. Changes are announced to screen readers.
class ProgrammerStatusLine extends ConsumerWidget {
  /// Creates the status line.
  const ProgrammerStatusLine({super.key});

  /// The text of [operation]'s key, as it reads in the pending operand.
  static String operationSymbol(
    AppLocalizations l10n,
    ProgrammerOperation operation,
  ) => switch (operation) {
    ProgrammerOperation.add => '+',
    ProgrammerOperation.subtract => '−',
    ProgrammerOperation.multiply => '×',
    ProgrammerOperation.divide => '÷',
    ProgrammerOperation.and => l10n.programmerKeyAnd,
    ProgrammerOperation.or => l10n.programmerKeyOr,
    ProgrammerOperation.xor => l10n.programmerKeyXor,
    ProgrammerOperation.shiftLeft => l10n.programmerKeyShiftLeft,
    ProgrammerOperation.shiftRight => l10n.programmerKeyShiftRight,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final style = AppTypography.of(context).caption;
    final format = ref.watch(numberFormatProvider);
    final session = ref.watch(programmerProvider);

    final pending = session.pending;
    final pendingText = pending == null
        ? ''
        : '${formatInBase(format, session, pending.left)} '
              '${operationSymbol(l10n, pending.operation)}';

    final Widget content;
    if (session.error != null) {
      content = Text(
        l10n.errorDivisionByZero,
        style: style.copyWith(color: colors.error),
      );
    } else {
      content = Row(
        children: [
          Expanded(
            child: Text(
              pendingText,
              style: style.copyWith(color: colors.textMuted),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ),
          if (session.overflow) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.warning_amber_rounded,
              size: style.fontSize,
              color: colors.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              flex: pendingText.isEmpty ? 100 : 2,
              child: Text(
                l10n.programmerOverflowNotice(session.word.bits),
                style: style.copyWith(color: colors.textPrimary),
              ),
            ),
          ],
        ],
      );
    }

    final lineHeight = MediaQuery.textScalerOf(context)
        .scale(style.fontSize! * style.height!);

    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: lineHeight),
        child: content,
      ),
    );
  }
}
