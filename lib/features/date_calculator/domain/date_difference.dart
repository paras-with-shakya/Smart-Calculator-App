import 'package:smart_calculator/features/date_calculator/domain/calendar_date.dart';

/// The gap between two calendar dates, in every unit the screen shows.
class DateDifference {
  const DateDifference({
    required this.years,
    required this.months,
    required this.days,
    required this.totalMonths,
    required this.totalDays,
  });

  /// Whole years in the gap.
  final int years;

  /// Whole months left after [years] (0–11).
  final int months;

  /// Days left after [years] and [months] (0–30).
  final int days;

  /// Whole months in the gap, years included (`years * 12 + months`).
  final int totalMonths;

  /// Every day in the gap.
  final int totalDays;

  /// Whole weeks in [totalDays].
  int get weeks => totalDays ~/ 7;

  /// Days left after [weeks].
  int get daysAfterWeeks => totalDays % 7;
}

/// The gap between [a] and [b], in either order (the gap is always
/// positive; swapping the dates gives the same result).
///
/// The months are the most that can be added to the earlier date
/// ([addMonths], with its month-end clamping) without passing the later
/// one, and the days are what's left. This keeps the two tools in step:
/// the gap from 31 Jan to 30 Apr is 3 months 0 days, because
/// 31 Jan + 3 months *is* 30 Apr.
DateDifference dateDifference(DateTime a, DateTime b) {
  assert(a.isUtc && b.isUtc, 'Calendar dates are UTC; use calendarDate().');
  final (earlier, later) = a.isAfter(b) ? (b, a) : (a, b);

  var months = (later.year - earlier.year) * 12 + (later.month - earlier.month);
  if (addMonths(earlier, months)!.isAfter(later)) months--;
  final anchor = addMonths(earlier, months)!;

  return DateDifference(
    years: months ~/ 12,
    months: months % 12,
    days: daysBetween(anchor, later),
    totalMonths: months,
    totalDays: daysBetween(earlier, later),
  );
}
