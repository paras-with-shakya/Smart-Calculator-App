import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_radius.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// A horizontal two-segment bar showing how a whole splits into a base
/// part and an added-on part, with a legend underneath — e.g. a loan's
/// principal vs. interest, or an amount vs. its GST.
///
/// Deliberately not a donut/pie: a 2-segment donut is a well-documented
/// anti-pattern for comparing two part-to-whole values this close in kind.
/// The accent colour ([AppColors.primary]) always marks the *added* part —
/// the one worth noticing — and neutral ([AppColors.secondary]) marks the
/// *base*, consistently across every use.
class ShareOfWholeBar extends StatelessWidget {
  /// Creates the bar. [baseValue] and [addedValue] must sum to a positive
  /// total: every caller validates its own inputs before reaching this
  /// point (principal/amount `> 0`), so a non-positive total here is a
  /// caller-contract bug, not reachable user input.
  const ShareOfWholeBar({
    super.key,
    required this.baseLabel,
    required this.baseValue,
    required this.baseValueText,
    required this.addedLabel,
    required this.addedValue,
    required this.addedValueText,
  }) : assert(
         baseValue + addedValue > 0,
         'ShareOfWholeBar requires a positive total',
       );

  /// Label for the base (neutral-toned) segment.
  final String baseLabel;

  /// Value of the base segment, used only to compute the proportion.
  final double baseValue;

  /// Already-formatted display text for the base segment's legend.
  final String baseValueText;

  /// Label for the added (accent-toned) segment.
  final String addedLabel;

  /// Value of the added segment, used only to compute the proportion.
  final double addedValue;

  /// Already-formatted display text for the added segment's legend.
  final String addedValueText;

  static const double _barHeight = 16;

  /// The gap between the two segments, so they read as two parts even
  /// where their colours are close.
  static const double _segmentGap = 2;

  /// The smallest share of the bar a segment ever gets (2%), so a
  /// near-zero segment still renders a visible sliver. The legend's value
  /// always shows the true figure regardless of the bar's visual width.
  static const int _minFlex = 20;
  static const int _flexScale = 1000;

  int _flexFor(double value, double total) =>
      ((value / total) * _flexScale).round().clamp(_minFlex, _flexScale);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = baseValue + addedValue;
    final baseFlex = _flexFor(baseValue, total);
    final addedFlex = _flexFor(addedValue, total);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Material(
          color: Colors.transparent,
          shape: AppRadius.shape(AppRadius.sm),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: _barHeight,
            // Stretch: a ColoredBox without a child takes the smallest
            // height it is allowed, so without it both segments were 0 dp
            // tall and the bar was invisible (found on the phone, Phase 11).
            child: Row(
              crossAxisAlignment: .stretch,
              children: [
                Expanded(
                  flex: baseFlex,
                  child: ColoredBox(color: colors.secondary),
                ),
                const SizedBox(width: _segmentGap),
                Expanded(
                  flex: addedFlex,
                  child: ColoredBox(color: colors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: _Legend(
                swatchColor: colors.secondary,
                label: baseLabel,
                valueText: baseValueText,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Legend(
                swatchColor: colors.primary,
                label: addedLabel,
                valueText: addedValueText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.swatchColor,
    required this.label,
    required this.valueText,
  });

  final Color swatchColor;
  final String label;
  final String valueText;

  static const double _swatchSize = 10;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    return Row(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: swatchColor,
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: _swatchSize),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                label,
                style: typography.caption.copyWith(color: colors.textMuted),
              ),
              Text(
                valueText,
                style: typography.body.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
