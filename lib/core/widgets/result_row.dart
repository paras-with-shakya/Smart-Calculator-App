import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';

/// Shown in place of a result card while a form's inputs are incomplete or
/// invalid — a plain muted line, not `EmptyState` (which is sized for a
/// whole empty screen, not a compact "nothing yet" line inside a card).
class ResultPlaceholder extends StatelessWidget {
  /// Creates a placeholder card saying [message].
  const ResultPlaceholder({super.key, required this.message});

  /// What to tell the user, such as "Enter values to see the result".
  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Text(
      message,
      style: AppTypography.of(context).body
          .copyWith(color: AppColors.of(context).textMuted),
    ),
  );
}

/// One label/value line inside a result card.
class ResultRow extends StatelessWidget {
  /// Creates a row showing [value] next to [label].
  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.wrapValue = false,
  });

  /// What the value is.
  final String label;

  /// The already-formatted value text.
  final String value;

  /// Whether this is the headline figure (larger, e.g. the EMI itself),
  /// rather than a supporting figure (e.g. total interest).
  final bool emphasized;

  /// Whether a long [value] wraps onto more lines instead of being cut off
  /// with an ellipsis. For values that are prose rather than a number, such
  /// as a date or a "2 years, 3 months" span.
  final bool wrapValue;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: wrapValue ? .start : .center,
        children: [
          Expanded(
            child: Text(
              label,
              style: typography.body.copyWith(color: colors.textMuted),
              overflow: .ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: .end,
              overflow: wrapValue ? null : .ellipsis,
              style: (emphasized ? typography.title : typography.body).copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
