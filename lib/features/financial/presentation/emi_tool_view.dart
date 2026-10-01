import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/share_of_whole_bar.dart';
import 'package:smart_calculator/features/financial/domain/emi.dart';
import 'package:smart_calculator/features/financial/presentation/financial_number_format.dart';
import 'package:smart_calculator/features/financial/presentation/financial_result_widgets.dart';
import 'package:smart_calculator/features/financial/presentation/financial_validation_messages.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// EMI: loan amount, interest rate and tenure in, monthly EMI, total
/// interest and total payment out, plus a principal/interest share bar.
class EmiToolView extends ConsumerStatefulWidget {
  const EmiToolView({super.key});

  @override
  ConsumerState<EmiToolView> createState() => _EmiToolViewState();
}

class _EmiToolViewState extends ConsumerState<EmiToolView> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _tenure = TextEditingController();
  TenureUnit _tenureUnit = TenureUnit.years;

  static final _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _tenure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(numberFormatProvider);

    return ListenableBuilder(
      listenable: Listenable.merge([_principal, _rate, _tenure]),
      builder: (context, _) {
        final principalText = _principal.text.trim();
        final rateText = _rate.text.trim();
        final tenureText = _tenure.text.trim();
        final principal = double.tryParse(principalText) ?? 0;
        final rate = double.tryParse(rateText) ?? 0;
        final tenureRaw = double.tryParse(tenureText) ?? 0;
        final tenureMonths = tenureMonthsFrom(
          value: tenureRaw,
          unit: _tenureUnit,
        );

        final errors = validateEmiInputs(
          principal: principal,
          ratePercent: rate,
          tenureMonths: tenureMonths,
        );
        final allFilled =
            principalText.isNotEmpty &&
            rateText.isNotEmpty &&
            tenureText.isNotEmpty;
        final result = allFilled && !errors.hasErrors
            ? calculateEmi(
                principal: principal,
                ratePercent: rate,
                tenureMonths: tenureMonths,
              )
            : null;

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            AppTextField(
              label: l10n.financialEmiPrincipalLabel,
              controller: _principal,
              prefixText: '₹ ',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: principalText.isEmpty
                  ? null
                  : fieldErrorMessage(l10n, errors.principal),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.financialEmiRateLabel,
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
                      max: maxEmiRatePercent.toInt(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: .start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.financialEmiTenureLabel,
                    controller: _tenure,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _decimalFormatters,
                    errorText: tenureText.isEmpty
                        ? null
                        : fieldErrorMessage(
                            l10n,
                            errors.tenureMonths,
                            max: maxEmiTenureMonths,
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 168,
                  child: AppChoiceGroup<TenureUnit>(
                    options: [
                      AppChoice(
                        value: TenureUnit.years,
                        label: l10n.financialTenureUnitYears,
                      ),
                      AppChoice(
                        value: TenureUnit.months,
                        label: l10n.financialTenureUnitMonths,
                      ),
                    ],
                    selected: _tenureUnit,
                    onChanged: (unit) => setState(() => _tenureUnit = unit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (result == null)
              const FinancialResultPlaceholder()
            else
              AppCard(
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    FinancialResultRow(
                      label: l10n.financialEmiMonthlyLabel,
                      value: formatMoney(format, result.monthlyEmi),
                      emphasized: true,
                    ),
                    FinancialResultRow(
                      label: l10n.financialEmiTotalInterestLabel,
                      value: formatMoney(format, result.totalInterest),
                    ),
                    FinancialResultRow(
                      label: l10n.financialEmiTotalPaymentLabel,
                      value: formatMoney(format, result.totalPayment),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ShareOfWholeBar(
                      baseLabel: l10n.financialEmiChartPrincipalLabel,
                      baseValue: principal,
                      baseValueText: formatMoney(format, principal),
                      addedLabel: l10n.financialEmiChartInterestLabel,
                      addedValue: result.totalInterest,
                      addedValueText: formatMoney(format, result.totalInterest),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
