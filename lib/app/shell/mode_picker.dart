import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_bottom_sheet.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The mode pill for compact windows: shows the current mode and opens the
/// mode sheet.
class ModePickerButton extends ConsumerWidget {
  /// Creates the mode pill.
  const ModePickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(currentModeProvider);
    return Tooltip(
      message: l10n.changeModeTooltip,
      child: AppButton(
        label: mode.label(l10n),
        variant: AppButtonVariant.secondary,
        trailingIcon: Icons.arrow_drop_down,
        onPressed: () => showAppBottomSheet<void>(
          context: context,
          title: l10n.modeSheetTitle,
          builder: (_) => const _ModeGrid(),
        ),
      ),
    );
  }
}

/// Every mode as a grid of tiles. The current mode is selected; choosing a
/// tile switches to it and closes the sheet.
class _ModeGrid extends ConsumerWidget {
  const _ModeGrid();

  static const int _columns = 3;
  static const int _columnsForLargeText = 2;

  /// From this text scale, labels such as "Programmer" no longer fit three
  /// columns on a phone, so the grid switches to two.
  static const double _largeTextScale = 1.15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentModeProvider);
    final columns = MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale
        ? _columnsForLargeText
        : _columns;
    const modes = CalculatorMode.values;
    final rows = [
      for (var start = 0; start < modes.length; start += columns)
        modes.sublist(start, math.min(start + columns, modes.length)),
    ];

    return Column(
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: .stretch,
              children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: column < row.length
                        ? _ModeTile(
                            mode: row[column],
                            selected: row[column] == current,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeTile extends ConsumerWidget {
  const _ModeTile({required this.mode, required this.selected});

  final CalculatorMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    selected: selected,
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.md,
      horizontal: AppSpacing.sm,
    ),
    onTap: () {
      ref.read(currentModeProvider.notifier).select(mode);
      Navigator.of(context).pop();
    },
    child: Column(
      mainAxisSize: .min,
      children: [
        Icon(mode.icon),
        const SizedBox(height: AppSpacing.sm),
        // One line, shrunk if a long label or translation does not fit, rather
        // than broken in the middle of a word.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            mode.label(AppLocalizations.of(context)),
            maxLines: 1,
            style: AppTypography.of(context).label,
          ),
        ),
      ],
    ),
  );
}
