import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/features/financial/domain/percentage.dart';
import 'package:smart_calculator/features/financial/presentation/financial_number_format.dart';
import 'package:smart_calculator/features/financial/presentation/financial_result_widgets.dart';
import 'package:smart_calculator/features/financial/presentation/financial_validation_messages.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Percentage: one flexible tool with three common operations — "X% of Y",
/// "X is what % of Y" and "increase/decrease Y by X%".
class PercentageToolView extends ConsumerStatefulWidget {
  const PercentageToolView({super.key});

  @override
  ConsumerState<PercentageToolView> createState() => _PercentageToolViewState();
}

class _PercentageToolViewState extends ConsumerState<PercentageToolView> {
  final _x = TextEditingController();
  final _y = TextEditingController();
  PercentageOperation _operation = PercentageOperation.percentOf;
  PercentageDirection _direction = PercentageDirection.increase;

  static final _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  (String xLabel, String yLabel) _fieldLabels(AppLocalizations l10n) =>
      switch (_operation) {
        PercentageOperation.percentOf => (
          l10n.financialPercentOfXLabel,
          l10n.financialPercentOfYLabel,
        ),
        PercentageOperation.whatPercent => (
          l10n.financialPercentWhatXLabel,
          l10n.financialPercentWhatYLabel,
        ),
        PercentageOperation.changeBy => (
          l10n.financialPercentChangeXLabel,
          l10n.financialPercentChangeYLabel,
        ),
      };

  String _operationLabel(
    AppLocalizations l10n,
    PercentageOperation operation,
  ) => switch (operation) {
    PercentageOperation.percentOf => l10n.financialPercentOpPercentOf,
    PercentageOperation.whatPercent => l10n.financialPercentOpWhatPercent,
    PercentageOperation.changeBy => l10n.financialPercentOpChangeBy,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(numberFormatProvider);
    final (xLabel, yLabel) = _fieldLabels(l10n);

    return ListenableBuilder(
      listenable: Listenable.merge([_x, _y]),
      builder: (context, _) {
        final xText = _x.text.trim();
        final yText = _y.text.trim();
        final x = double.tryParse(xText) ?? 0;
        final y = double.tryParse(yText) ?? 0;
        final allFilled = xText.isNotEmpty && yText.isNotEmpty;

        final errors = switch (_operation) {
          PercentageOperation.percentOf => validatePercentOfInputs(x: x, y: y),
          PercentageOperation.whatPercent => validateWhatPercentInputs(
            x: x,
            y: y,
          ),
          PercentageOperation.changeBy => validateChangeByInputs(
            x: x,
            y: y,
            direction: _direction,
          ),
        };

        final double? result = allFilled && !errors.hasErrors
            ? switch (_operation) {
                PercentageOperation.percentOf => calculatePercentOf(x: x, y: y),
                PercentageOperation.whatPercent => calculateWhatPercent(
                  x: x,
                  y: y,
                ),
                PercentageOperation.changeBy => calculateChangeBy(
                  x: x,
                  y: y,
                  direction: _direction,
                ),
              }
            : null;

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              l10n.financialPercentOperationLabel,
              style: AppTypography.of(context).label
                  .copyWith(color: AppColors.of(context).textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppChoiceGroup<PercentageOperation>(
              options: [
                for (final operation in PercentageOperation.values)
                  AppChoice(
                    value: operation,
                    label: _operationLabel(l10n, operation),
                  ),
              ],
              selected: _operation,
              onChanged: (operation) => setState(() => _operation = operation),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_operation == PercentageOperation.changeBy) ...[
              AppChoiceGroup<PercentageDirection>(
                options: [
                  AppChoice(
                    value: PercentageDirection.increase,
                    label: l10n.financialPercentDirectionIncrease,
                  ),
                  AppChoice(
                    value: PercentageDirection.decrease,
                    label: l10n.financialPercentDirectionDecrease,
                  ),
                ],
                selected: _direction,
                onChanged: (direction) =>
                    setState(() => _direction = direction),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: xLabel,
              controller: _x,
              suffixText: _operation == PercentageOperation.whatPercent
                  ? null
                  : '%',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: xText.isEmpty
                  ? null
                  : fieldErrorMessage(
                      l10n,
                      errors.x,
                      max:
                          _operation == PercentageOperation.changeBy &&
                              _direction == PercentageDirection.decrease
                          ? maxDecreasePercent.toInt()
                          : null,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: yLabel,
              controller: _y,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _decimalFormatters,
              errorText: yText.isEmpty
                  ? null
                  : fieldErrorMessage(l10n, errors.y),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (result == null)
              const FinancialResultPlaceholder()
            else
              AppCard(
                child: FinancialResultRow(
                  label: l10n.financialPercentResultLabel,
                  value: _operation == PercentageOperation.whatPercent
                      ? '${formatPercent(format, result)}%'
                      : formatMoney(format, result),
                  emphasized: true,
                ),
              ),
          ],
        );
      },
    );
  }
}
