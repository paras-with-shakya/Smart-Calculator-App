import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';
import 'package:smart_calculator/features/financial/domain/simple_interest.dart';
import 'package:smart_calculator/features/financial/presentation/financial_number_format.dart';
import 'package:smart_calculator/features/financial/presentation/financial_result_widgets.dart';
import 'package:smart_calculator/features/financial/presentation/financial_validation_messages.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Simple interest: principal, rate and time in, interest and total out.
class SimpleInterestToolView extends ConsumerStatefulWidget {
  const SimpleInterestToolView({super.key});

  @override
  ConsumerState<SimpleInterestToolView> createState() =>
      _SimpleInterestToolViewState();
}

class _SimpleInterestToolViewState
    extends ConsumerState<SimpleInterestToolView> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _years = TextEditingController();

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

        final errors = validateSimpleInterestInputs(
          principal: principal,
          ratePercent: rate,
          years: years,
        );
        final allFilled =
            principalText.isNotEmpty &&
            rateText.isNotEmpty &&
            yearsText.isNotEmpty;
        final result = allFilled && !errors.hasErrors
            ? calculateSimpleInterest(
                principal: principal,
                ratePercent: rate,
                years: years,
              )
            : null;

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            AppTextField(
              label: l10n.financialSiPrincipalLabel,
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
              label: l10n.financialSiRateLabel,
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
                      max: maxSimpleInterestRatePercent.toInt(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.financialSiTimeLabel,
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
                      max: maxSimpleInterestYears.toInt(),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (result == null)
              const FinancialResultPlaceholder()
            else
              AppCard(
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    ResultRow(
                      label: l10n.financialSiInterestLabel,
                      value: formatMoney(format, result.interest),
                      emphasized: true,
                    ),
                    ResultRow(
                      label: l10n.financialSiTotalLabel,
                      value: formatMoney(format, result.totalAmount),
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
