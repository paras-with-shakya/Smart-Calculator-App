import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/features/financial/domain/tip.dart';
import 'package:smart_calculator/features/financial/presentation/financial_number_format.dart';
import 'package:smart_calculator/features/financial/presentation/financial_result_widgets.dart';
import 'package:smart_calculator/features/financial/presentation/financial_validation_messages.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Tip: bill, tip % and an optional split count in, tip amount, total and
/// per-person share out.
class TipToolView extends ConsumerStatefulWidget {
  const TipToolView({super.key});

  @override
  ConsumerState<TipToolView> createState() => _TipToolViewState();
}

class _TipToolViewState extends ConsumerState<TipToolView> {
  final _bill = TextEditingController();
  final _tip = TextEditingController();
  final _split = TextEditingController(text: '1');

  static final _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];
  static final _integerFormatters = [FilteringTextInputFormatter.digitsOnly];

  @override
  void dispose() {
    _bill.dispose();
    _tip.dispose();
    _split.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(numberFormatProvider);

    return ListenableBuilder(
      listenable: Listenable.merge([_bill, _tip, _split]),
      builder: (context, _) {
        final billText = _bill.text.trim();
        final tipText = _tip.text.trim();
        final splitText = _split.text.trim();
        final bill = double.tryParse(billText) ?? 0;
        final tipPercent = double.tryParse(tipText) ?? 0;
        final splitCount = int.tryParse(splitText) ?? 0;

        final errors = validateTipInputs(
          bill: bill,
          tipPercent: tipPercent,
          splitCount: splitCount,
        );
        final allFilled =
            billText.isNotEmpty && tipText.isNotEmpty && splitText.isNotEmpty;
        final result = allFilled && !errors.hasErrors
            ? calculateTip(
                bill: bill,
                tipPercent: tipPercent,
                splitCount: splitCount,
              )
            : null;

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            AppTextField(
              label: l10n.financialTipBillLabel,
              controller: _bill,
              prefixText: '₹ ',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: billText.isEmpty
                  ? null
                  : fieldErrorMessage(l10n, errors.bill),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.financialTipPercentLabel,
              controller: _tip,
              suffixText: '%',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: tipText.isEmpty
                  ? null
                  : fieldErrorMessage(
                      l10n,
                      errors.tipPercent,
                      max: maxTipPercent.toInt(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.financialTipSplitLabel,
              controller: _split,
              keyboardType: TextInputType.number,
              inputFormatters: _integerFormatters,
              errorText: splitText.isEmpty
                  ? null
                  : fieldErrorMessage(l10n, errors.splitCount),
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
                      label: l10n.financialTipPerPersonLabel,
                      value: formatMoney(format, result.perPerson),
                      emphasized: true,
                    ),
                    FinancialResultRow(
                      label: l10n.financialTipAmountLabel,
                      value: formatMoney(format, result.tipAmount),
                    ),
                    FinancialResultRow(
                      label: l10n.financialTipTotalLabel,
                      value: formatMoney(format, result.total),
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
