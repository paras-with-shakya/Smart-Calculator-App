import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';
import 'package:smart_calculator/core/widgets/share_of_whole_bar.dart';
import 'package:smart_calculator/features/financial/domain/gst.dart';
import 'package:smart_calculator/features/financial/presentation/financial_number_format.dart';
import 'package:smart_calculator/features/financial/presentation/financial_result_widgets.dart';
import 'package:smart_calculator/features/financial/presentation/financial_validation_messages.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

enum _SupplyType { intraState, interState }

/// GST: amount and rate in, with an exclusive/inclusive mode and an
/// intra/inter-state presentation toggle; base amount, GST amount, total
/// (and CGST/SGST or IGST) out, plus a base/GST share bar.
class GstToolView extends ConsumerStatefulWidget {
  const GstToolView({super.key});

  @override
  ConsumerState<GstToolView> createState() => _GstToolViewState();
}

class _GstToolViewState extends ConsumerState<GstToolView> {
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  GstMode _mode = GstMode.exclusive;
  _SupplyType _supplyType = _SupplyType.intraState;

  static final _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(numberFormatProvider);

    return ListenableBuilder(
      listenable: Listenable.merge([_amount, _rate]),
      builder: (context, _) {
        final amountText = _amount.text.trim();
        final rateText = _rate.text.trim();
        final amount = double.tryParse(amountText) ?? 0;
        final rate = double.tryParse(rateText) ?? 0;

        final errors = validateGstInputs(amount: amount, ratePercent: rate);
        final allFilled = amountText.isNotEmpty && rateText.isNotEmpty;
        final result = allFilled && !errors.hasErrors
            ? calculateGst(amount: amount, ratePercent: rate, mode: _mode)
            : null;

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            AppTextField(
              label: l10n.financialGstAmountLabel,
              controller: _amount,
              prefixText: '₹ ',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: amountText.isEmpty
                  ? null
                  : fieldErrorMessage(l10n, errors.amount),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.financialGstRateLabel,
              controller: _rate,
              suffixText: '%',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: rateText.isEmpty
                  ? null
                  : fieldErrorMessage(
                      l10n,
                      errors.ratePercent,
                      max: maxGstRatePercent.toInt(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.financialGstModeLabel,
              style: AppTypography.of(context).label
                  .copyWith(color: AppColors.of(context).textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppChoiceGroup<GstMode>(
              options: [
                AppChoice(
                  value: GstMode.exclusive,
                  label: l10n.financialGstModeExclusive,
                ),
                AppChoice(
                  value: GstMode.inclusive,
                  label: l10n.financialGstModeInclusive,
                ),
              ],
              selected: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.financialGstSupplyLabel,
              style: AppTypography.of(context).label
                  .copyWith(color: AppColors.of(context).textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppChoiceGroup<_SupplyType>(
              options: [
                AppChoice(
                  value: _SupplyType.intraState,
                  label: l10n.financialGstSupplyIntraState,
                ),
                AppChoice(
                  value: _SupplyType.interState,
                  label: l10n.financialGstSupplyInterState,
                ),
              ],
              selected: _supplyType,
              onChanged: (type) => setState(() => _supplyType = type),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (result == null)
              const FinancialResultPlaceholder()
            else
              ResultCard(
                children: [
                  ResultRow(
                    label: l10n.financialGstBaseLabel,
                    value: formatMoney(format, result.baseAmount),
                  ),
                  if (_supplyType == _SupplyType.intraState) ...[
                    ResultRow(
                      label: l10n.financialGstCgstLabel,
                      value: formatMoney(
                        format,
                        splitIntraState(result.gstAmount).cgst,
                      ),
                    ),
                    ResultRow(
                      label: l10n.financialGstSgstLabel,
                      value: formatMoney(
                        format,
                        splitIntraState(result.gstAmount).sgst,
                      ),
                    ),
                  ] else
                    ResultRow(
                      label: l10n.financialGstIgstLabel,
                      value: formatMoney(format, result.gstAmount),
                    ),
                  ResultRow(
                    label: l10n.financialGstTotalLabel,
                    value: formatMoney(format, result.totalAmount),
                    emphasized: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ShareOfWholeBar(
                    baseLabel: l10n.financialGstBaseLabel,
                    baseValue: result.baseAmount,
                    baseValueText: formatMoney(format, result.baseAmount),
                    addedLabel: l10n.financialGstAmountResultLabel,
                    addedValue: result.gstAmount,
                    addedValueText: formatMoney(format, result.gstAmount),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
