import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';
import 'package:smart_calculator/features/financial/domain/discount.dart';
import 'package:smart_calculator/features/financial/presentation/financial_number_format.dart';
import 'package:smart_calculator/features/financial/presentation/financial_result_widgets.dart';
import 'package:smart_calculator/features/financial/presentation/financial_validation_messages.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Discount: price and discount % in, discount amount and final price out.
class DiscountToolView extends ConsumerStatefulWidget {
  const DiscountToolView({super.key});

  @override
  ConsumerState<DiscountToolView> createState() => _DiscountToolViewState();
}

class _DiscountToolViewState extends ConsumerState<DiscountToolView> {
  final _price = TextEditingController();
  final _discount = TextEditingController();

  static final _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(numberFormatProvider);

    return ListenableBuilder(
      listenable: Listenable.merge([_price, _discount]),
      builder: (context, _) {
        final priceText = _price.text.trim();
        final discountText = _discount.text.trim();
        final price = double.tryParse(priceText) ?? 0;
        final discountPercent = double.tryParse(discountText) ?? 0;

        final errors = validateDiscountInputs(
          price: price,
          discountPercent: discountPercent,
        );
        final allFilled = priceText.isNotEmpty && discountText.isNotEmpty;
        final result = allFilled && !errors.hasErrors
            ? calculateDiscount(price: price, discountPercent: discountPercent)
            : null;

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            AppTextField(
              label: l10n.financialDiscountPriceLabel,
              controller: _price,
              prefixText: '₹ ',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: priceText.isEmpty
                  ? null
                  : fieldErrorMessage(l10n, errors.price),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.financialDiscountPercentLabel,
              controller: _discount,
              suffixText: '%',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: discountText.isEmpty
                  ? null
                  : fieldErrorMessage(
                      l10n,
                      errors.discountPercent,
                      max: maxDiscountPercent.toInt(),
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
                      label: l10n.financialDiscountFinalPriceLabel,
                      value: formatMoney(format, result.finalPrice),
                      emphasized: true,
                    ),
                    ResultRow(
                      label: l10n.financialDiscountAmountLabel,
                      value: formatMoney(format, result.discountAmount),
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
