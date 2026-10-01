import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/formatting/date_format_provider.dart';
import 'package:smart_calculator/core/time/clock_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_date_field.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';
import 'package:smart_calculator/features/date_calculator/domain/calendar_date.dart';
import 'package:smart_calculator/features/date_calculator/domain/date_difference.dart';
import 'package:smart_calculator/features/date_calculator/presentation/date_pick_range.dart';
import 'package:smart_calculator/features/date_calculator/presentation/date_text.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The gap between two dates, as years/months/days, total days, weeks and
/// months. The order of the two dates does not matter.
class DateDifferenceToolView extends ConsumerStatefulWidget {
  const DateDifferenceToolView({super.key});

  @override
  ConsumerState<DateDifferenceToolView> createState() =>
      _DateDifferenceToolViewState();
}

class _DateDifferenceToolViewState
    extends ConsumerState<DateDifferenceToolView> {
  late DateTime _from = calendarDate(ref.read(clockProvider)());
  late DateTime _to = _from;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(dateFormatProvider);
    final gap = dateDifference(_from, _to);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        AppDateField(
          label: l10n.dateFromLabel,
          value: _from,
          format: format.short,
          pickerHelpText: l10n.datePickerHelp,
          firstDate: pickerFirstDate,
          lastDate: pickerLastDate,
          onChanged: (date) => setState(() => _from = date),
        ),
        const SizedBox(height: AppSpacing.md),
        AppDateField(
          label: l10n.dateToLabel,
          value: _to,
          format: format.short,
          pickerHelpText: l10n.datePickerHelp,
          firstDate: pickerFirstDate,
          lastDate: pickerLastDate,
          onChanged: (date) => setState(() => _to = date),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          liveRegion: true,
          child: AppCard(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                ResultRow(
                  label: l10n.dateResultDifference,
                  value: describeSpan(l10n, gap),
                  emphasized: true,
                  wrapValue: true,
                ),
                ResultRow(
                  label: l10n.dateResultTotalDays,
                  value: l10n.dateDays(gap.totalDays),
                  wrapValue: true,
                ),
                ResultRow(
                  label: l10n.dateResultWeeks,
                  value: describeWeeks(l10n, gap),
                  wrapValue: true,
                ),
                ResultRow(
                  label: l10n.dateResultTotalMonths,
                  value: l10n.dateMonths(gap.totalMonths),
                  wrapValue: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
