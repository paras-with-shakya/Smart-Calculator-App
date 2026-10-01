import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Shown in place of a tool's result card while its inputs are incomplete
/// or invalid — a plain muted line, not `EmptyState` (which is sized for a
/// whole empty screen, not a compact "nothing yet" line inside a card).
class FinancialResultPlaceholder extends StatelessWidget {
  const FinancialResultPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Text(
      AppLocalizations.of(context).financialResultPlaceholder,
      style: AppTypography.of(context).body
          .copyWith(color: AppColors.of(context).textMuted),
    ),
  );
}

/// One label/value line inside a financial tool's result card.
class FinancialResultRow extends StatelessWidget {
  const FinancialResultRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  /// What the value is.
  final String label;

  /// The already-formatted value text.
  final String value;

  /// Whether this is the headline figure (larger, e.g. the EMI itself),
  /// rather than a supporting figure (e.g. total interest).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
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
              overflow: .ellipsis,
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
