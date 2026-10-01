import 'package:smart_calculator/features/date_calculator/domain/date_difference.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

String _join(AppLocalizations l10n, List<String> parts) => parts.isEmpty
    ? l10n.dateDays(0)
    : parts.reduce((first, second) => l10n.dateSpanJoin(first, second));

/// "2 years, 3 months, 5 days": the parts of [gap] that are not zero, or
/// "0 days" if all are.
String describeSpan(AppLocalizations l10n, DateDifference gap) => _join(l10n, [
  if (gap.years > 0) l10n.dateYears(gap.years),
  if (gap.months > 0) l10n.dateMonths(gap.months),
  if (gap.days > 0) l10n.dateDays(gap.days),
]);

/// "3 weeks, 1 day": whole weeks and the days after them.
String describeWeeks(AppLocalizations l10n, DateDifference gap) => _join(l10n, [
  if (gap.weeks > 0) l10n.dateWeeks(gap.weeks),
  if (gap.daysAfterWeeks > 0) l10n.dateDays(gap.daysAfterWeeks),
]);
