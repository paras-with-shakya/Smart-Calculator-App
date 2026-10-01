import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/features/financial/application/financial_tool_notifier.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
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
class FinancialToolPicker extends ConsumerWidget {
  /// Creates the picker.
  const FinancialToolPicker({super.key});

  static const double _tileWidth = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(financialToolProvider);
    final notifier = ref.read(financialToolProvider.notifier);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final tool in FinancialToolId.values)
          SizedBox(
            width: _tileWidth,
            child: AppCard(
              selected: tool == current,
              onTap: () {
                HapticFeedback.selectionClick();
                notifier.selectTool(tool);
              },
              child: Column(
                children: [
                  Icon(iconFor(tool)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    labelFor(l10n, tool),
                    textAlign: .center,
                    style: AppTypography.of(context).label,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
