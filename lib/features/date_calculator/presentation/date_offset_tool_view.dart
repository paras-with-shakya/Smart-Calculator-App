import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/date_format_provider.dart';
import 'package:smart_calculator/core/time/clock_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/core/widgets/app_date_field.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';
import 'package:smart_calculator/features/date_calculator/domain/calendar_date.dart';
import 'package:smart_calculator/features/date_calculator/domain/date_offset.dart';
import 'package:smart_calculator/features/date_calculator/presentation/date_pick_range.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// A date plus or minus some days, weeks, months or years.
class DateOffsetToolView extends ConsumerStatefulWidget {
  const DateOffsetToolView({super.key});

  @override
  ConsumerState<DateOffsetToolView> createState() => _DateOffsetToolViewState();
}

class _DateOffsetToolViewState extends ConsumerState<DateOffsetToolView> {
  final _amount = TextEditingController();
  late DateTime _start = calendarDate(ref.read(clockProvider)());
  DateDirection _direction = DateDirection.add;
  DateUnit _unit = DateUnit.days;

  /// Seven digits is as many as [maxDateAmount] needs; a longer entry would
  /// only be a "too large" error.
  static final _digitFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(7),
  ];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String _unitLabel(AppLocalizations l10n, DateUnit unit) => switch (unit) {
    DateUnit.days => l10n.dateUnitDays,
    DateUnit.weeks => l10n.dateUnitWeeks,
    DateUnit.months => l10n.dateUnitMonths,
    DateUnit.years => l10n.dateUnitYears,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(dateFormatProvider);

    return ListenableBuilder(
      listenable: _amount,
      builder: (context, _) {
        final amount = int.tryParse(_amount.text.trim());
        final result = amount == null
            ? null
            : offsetDate(
                start: _start,
                amount: amount,
                unit: _unit,
                direction: _direction,
              );

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            AppDateField(
              label: l10n.dateStartLabel,
              value: _start,
              format: format.short,
              pickerHelpText: l10n.datePickerHelp,
              firstDate: pickerFirstDate,
              lastDate: pickerLastDate,
              onChanged: (date) => setState(() => _start = date),
            ),
            const SizedBox(height: AppSpacing.md),
            AppChoiceGroup<DateDirection>(
              options: [
                AppChoice(
                  value: DateDirection.add,
                  label: l10n.dateDirectionAdd,
                ),
                AppChoice(
                  value: DateDirection.subtract,
                  label: l10n.dateDirectionSubtract,
                ),
              ],
              selected: _direction,
              onChanged: (direction) => setState(() => _direction = direction),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.dateAmountLabel,
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: _digitFormatters,
              errorText: result?.error == DateOffsetError.amountTooLarge
                  ? l10n.dateErrorAmountTooLarge(maxDateAmount)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.dateUnitLabel,
              style: AppTypography.of(context).label
                  .copyWith(color: AppColors.of(context).textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppChoiceGroup<DateUnit>(
              options: [
                for (final unit in DateUnit.values)
                  AppChoice(value: unit, label: _unitLabel(l10n, unit)),
              ],
              selected: _unit,
              onChanged: (unit) => setState(() => _unit = unit),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              liveRegion: true,
              child: switch (result) {
                DateOffsetResult(:final date?) => AppCard(
                  child: ResultRow(
                    label: l10n.dateResultDate,
                    value: format.long(date),
                    emphasized: true,
                    wrapValue: true,
                  ),
                ),
                DateOffsetResult(error: DateOffsetError.outOfRange) =>
                  ResultPlaceholder(message: l10n.dateErrorOutOfRange),
                _ => ResultPlaceholder(message: l10n.dateOffsetPlaceholder),
              },
            ),
          ],
        );
      },
    );
  }
}
