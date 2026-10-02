import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/features/financial/application/financial_tool_notifier.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The icon shown for [tool].
IconData iconFor(FinancialToolId tool) => switch (tool) {
  FinancialToolId.emi => Icons.payments_outlined,
  FinancialToolId.simpleInterest => Icons.trending_up,
  FinancialToolId.compoundInterest => Icons.show_chart,
  FinancialToolId.gst => Icons.receipt_long_outlined,
  FinancialToolId.discount => Icons.sell_outlined,
  FinancialToolId.tip => Icons.room_service_outlined,
  FinancialToolId.percentage => Icons.percent,
};

/// The label shown for [tool].
String labelFor(AppLocalizations l10n, FinancialToolId tool) => switch (tool) {
  FinancialToolId.emi => l10n.financialToolEmi,
  FinancialToolId.simpleInterest => l10n.financialToolSimpleInterest,
  FinancialToolId.compoundInterest => l10n.financialToolCompoundInterest,
  FinancialToolId.gst => l10n.financialToolGst,
  FinancialToolId.discount => l10n.financialToolDiscount,
  FinancialToolId.tip => l10n.financialToolTip,
  FinancialToolId.percentage => l10n.financialToolPercentage,
};

/// A wrapping grid of tiles, one per [FinancialToolId], the current one
/// tinted with [AppCard.selected] — not `AppChoiceGroup`, which falls back
/// to a tall vertical radio list once labels stop fitting a segmented row
/// (likely with this many options on a phone width), mirroring exactly why
/// the converter's own category picker made the same choice.
///
/// Every tile is the same width: at least [_minTileWidth], and wide enough
/// for the longest *word* of any label at the current text size. A label of
/// several words ("Compound interest") may wrap between its words, but a
/// word ("Percentage") is never broken in the middle, at any text size.
class FinancialToolPicker extends ConsumerWidget {
  /// Creates the picker.
  const FinancialToolPicker({super.key});

  static const double _minTileWidth = 96;

  /// Side padding of a tile, the same as the converter's category tiles.
  /// Narrower than [AppCard]'s default, so that the longest word at 100%
  /// text still leaves three tiles to a row on a 360 dp phone.
  static const EdgeInsets _tilePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.md,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(financialToolProvider);
    final notifier = ref.read(financialToolProvider.notifier);
    final labelStyle = AppTypography.of(context).label;
    final widest = _widestWord(
      [for (final tool in FinancialToolId.values) labelFor(l10n, tool)],
      _drawnStyle(context, labelStyle),
      MediaQuery.textScalerOf(context),
      Directionality.of(context),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitting = math.max(
          _minTileWidth,
          widest.ceilToDouble() + _tilePadding.horizontal,
        );
        // Never wider than the space there is; a word then breaks only if
        // even a whole row cannot hold it.
        final tileWidth = constraints.hasBoundedWidth
            ? math.min(fitting, constraints.maxWidth)
            : fitting;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tool in FinancialToolId.values)
              SizedBox(
                width: tileWidth,
                child: AppCard(
                  selected: tool == current,
                  padding: _tilePadding,
                  onTap: () {
                    ref.read(keyFeedbackProvider).select();
                    notifier.selectTool(tool);
                  },
                  child: Column(
                    children: [
                      Icon(iconFor(tool)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        labelFor(l10n, tool),
                        textAlign: .center,
                        style: labelStyle,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// [style] as a [Text] here draws it: on top of the ambient text style,
  /// and bold when the platform asks for bold text.
  static TextStyle _drawnStyle(BuildContext context, TextStyle style) {
    final drawn = DefaultTextStyle.of(context).style.merge(style);
    return MediaQuery.boldTextOf(context)
        ? drawn.merge(const TextStyle(fontWeight: FontWeight.bold))
        : drawn;
  }

  /// The width of the widest word in [labels], each on one line.
  static double _widestWord(
    List<String> labels,
    TextStyle style,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    var widest = 0.0;
    for (final label in labels) {
      for (final word in label.split(RegExp(r'\s+'))) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        widest = math.max(widest, painter.width);
        painter.dispose();
      }
    }
    return widest;
  }
}
