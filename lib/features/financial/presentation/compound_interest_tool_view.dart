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
import 'package:smart_calculator/features/financial/domain/compound_interest.dart';
import 'package:smart_calculator/features/financial/presentation/financial_number_format.dart';
import 'package:smart_calculator/features/financial/presentation/financial_result_widgets.dart';
import 'package:smart_calculator/features/financial/presentation/financial_validation_messages.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Compound interest: principal, rate, time and compounding frequency in,
/// interest earned and total amount out.
class CompoundInterestToolView extends ConsumerStatefulWidget {
  const CompoundInterestToolView({super.key});

  @override
  ConsumerState<CompoundInterestToolView> createState() =>
      _CompoundInterestToolViewState();
}

class _CompoundInterestToolViewState
    extends ConsumerState<CompoundInterestToolView> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _years = TextEditingController();
  CompoundingFrequency _frequency = CompoundingFrequency.annual;

  static final _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  String _frequencyLabel(
    AppLocalizations l10n,
    CompoundingFrequency frequency,
  ) => switch (frequency) {
    CompoundingFrequency.annual => l10n.financialCiFrequencyAnnual,
    CompoundingFrequency.semiAnnual => l10n.financialCiFrequencySemiAnnual,
    CompoundingFrequency.quarterly => l10n.financialCiFrequencyQuarterly,
    CompoundingFrequency.monthly => l10n.financialCiFrequencyMonthly,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(numberFormatProvider);

    return ListenableBuilder(
      listenable: Listenable.merge([_principal, _rate, _years]),
      builder: (context, _) {
        final principalText = _principal.text.trim();
        final rateText = _rate.text.trim();
        final yearsText = _years.text.trim();
        final principal = double.tryParse(principalText) ?? 0;
        final rate = double.tryParse(rateText) ?? 0;
        final years = double.tryParse(yearsText) ?? 0;

        final errors = validateCompoundInterestInputs(
          principal: principal,
          ratePercent: rate,
          years: years,
        );
        final allFilled =
            principalText.isNotEmpty &&
            rateText.isNotEmpty &&
            yearsText.isNotEmpty;
        final result = allFilled && !errors.hasErrors
            ? calculateCompoundInterest(
                principal: principal,
                ratePercent: rate,
                years: years,
                frequency: _frequency,
              )
            : null;

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            AppTextField(
              label: l10n.financialCiPrincipalLabel,
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
              label: l10n.financialCiRateLabel,
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
                      max: maxCompoundInterestRatePercent.toInt(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.financialCiTimeLabel,
              controller: _years,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: yearsText.isEmpty
                  ? null
                  : fieldErrorMessage(
                      l10n,
                      errors.years,
                      max: maxCompoundInterestYears.toInt(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.financialCiFrequencyLabel,
              style: AppTypography.of(context).label
                  .copyWith(color: AppColors.of(context).textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppChoiceGroup<CompoundingFrequency>(
              options: [
                for (final frequency in CompoundingFrequency.values)
                  AppChoice(
                    value: frequency,
                    label: _frequencyLabel(l10n, frequency),
                  ),
              ],
              selected: _frequency,
              onChanged: (frequency) => setState(() => _frequency = frequency),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (result == null)
              const FinancialResultPlaceholder()
            else
              ResultCard(
                children: [
                  ResultRow(
                    label: l10n.financialCiInterestLabel,
                    value: formatMoney(format, result.interest),
                    emphasized: true,
                  ),
                  ResultRow(
                    label: l10n.financialCiTotalLabel,
                    value: formatMoney(format, result.totalAmount),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
