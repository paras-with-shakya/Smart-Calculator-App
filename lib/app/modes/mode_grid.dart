import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Every mode as a grid of tiles, with [selected] marked. Used by the mode
/// sheet (choosing a mode switches to it) and by Settings (choosing the mode
/// the app opens in).
class ModeGrid extends StatelessWidget {
  /// Creates the grid.
  const ModeGrid({super.key, required this.selected, required this.onSelected});

  /// The mode drawn as selected.
  final CalculatorMode selected;

  /// Called with the mode a tile stands for when it is tapped.
  final ValueChanged<CalculatorMode> onSelected;

  static const int _columns = 3;
  static const int _columnsForLargeText = 2;

  /// From this text scale, labels such as "Programmer" no longer fit three
  /// columns on a phone, so the grid switches to two.
  static const double _largeTextScale = 1.15;

  @override
  Widget build(BuildContext context) {
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
                            selected: row[column] == selected,
                            onTap: () => onSelected(row[column]),
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

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final CalculatorMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    selected: selected,
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.md,
      horizontal: AppSpacing.sm,
    ),
    onTap: onTap,
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
