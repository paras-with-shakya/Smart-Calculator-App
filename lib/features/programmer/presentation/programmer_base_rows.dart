import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/display_text.dart';
import 'package:smart_calculator/features/programmer/application/programmer_notifier.dart';
import 'package:smart_calculator/features/programmer/domain/programmer_session.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_formatting.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The number in all four bases at once. The row of the base being typed in
/// is selected; tapping another row switches to it, so this is both the
/// conversion readout and the base selector.
///
/// Hexadecimal, octal and binary show the bits; decimal shows the value (so
/// a negative signed number reads as `-5` in decimal and `FB` in hex). Binary
/// is always zero-padded to the full word, in lines of 16 bits, so its height
/// depends only on the word size and the keypad below never moves while
/// typing.
class ProgrammerBaseRows extends ConsumerWidget {
  /// Creates the readout.
  const ProgrammerBaseRows({super.key});

  /// The readout rows' order, as on a programmer's calculator.
  static const List<ProgrammerBase> order = [
    ProgrammerBase.hexadecimal,
    ProgrammerBase.decimal,
    ProgrammerBase.octal,
    ProgrammerBase.binary,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(programmerProvider);
    final format = ref.watch(numberFormatProvider);
    final notifier = ref.read(programmerProvider.notifier);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, base) in order.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _BaseRow(
            base: base,
            session: session,
            format: format,
            onSelected: () => notifier.setBase(base),
          ),
        ],
      ],
    );
  }
}

class _BaseRow extends StatelessWidget {
  const _BaseRow({
    required this.base,
    required this.session,
    required this.format,
    required this.onSelected,
  });

  final ProgrammerBase base;
  final ProgrammerSession session;
  final LocalizedNumberFormat format;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    final active = session.base == base;
    final foreground = active ? colors.onPrimaryContainer : colors.textPrimary;

    final (label, name) = switch (base) {
      ProgrammerBase.hexadecimal => (
        l10n.programmerBaseHex,
        l10n.programmerBaseNameHex,
      ),
      ProgrammerBase.decimal => (
        l10n.programmerBaseDec,
        l10n.programmerBaseNameDec,
      ),
      ProgrammerBase.octal => (
        l10n.programmerBaseOct,
        l10n.programmerBaseNameOct,
      ),
      ProgrammerBase.binary => (
        l10n.programmerBaseBin,
        l10n.programmerBaseNameBin,
      ),
    };

    final (lines, spoken) = switch (base) {
      ProgrammerBase.hexadecimal => (
        [formatHexadecimal(session.current)],
        spokenDigits(formatHexadecimal(session.current)),
      ),
      ProgrammerBase.octal => (
        [formatOctal(session.current)],
        spokenDigits(formatOctal(session.current)),
      ),
      ProgrammerBase.binary => (
        formatBinaryLines(session.word, session.current),
        spokenDigits(formatBinaryLines(session.word, session.current).join()),
      ),
      ProgrammerBase.decimal => (
        [formatDecimal(format, session)],
        formatDecimal(format, session),
      ),
    };

    return Semantics(
      container: true,
      button: true,
      selected: active,
      liveRegion: active,
      label: l10n.programmerBaseRowSemantics(name, spoken),
      onTap: onSelected,
      excludeSemantics: true,
      child: AppCard(
        selected: active,
        onTap: onSelected,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension - 2 * AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: .center,
            children: [
              // At least 40 dp so the four labels line up, but as wide as the
              // label needs at a large text size (never broken mid-word).
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.xxl - AppSpacing.sm,
                ),
                child: Text(
                  label,
                  softWrap: false,
                  style: typography.label.copyWith(
                    color: active ? foreground : colors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    for (final line in lines)
                      DisplayText(
                        line,
                        style: typography.mono,
                        color: foreground,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
