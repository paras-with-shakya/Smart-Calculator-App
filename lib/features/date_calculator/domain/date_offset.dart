import 'package:smart_calculator/features/date_calculator/domain/calendar_date.dart';

/// What the amount in "add or subtract" counts.
enum DateUnit { days, weeks, months, years }

/// Whether the amount is added to or taken from the date.
enum DateDirection { add, subtract }

/// The most the amount can be, in any unit.
const int maxDateAmount = 1000000;

/// Why a date offset can't be calculated.
enum DateOffsetError {
  /// The amount is above [maxDateAmount].
  amountTooLarge,

  /// The result would fall outside years 1–9999.
  outOfRange,
}

/// The outcome of [offsetDate]: exactly one of [date] and [error] is set.
class DateOffsetResult {
  const DateOffsetResult.ok(DateTime this.date) : error = null;
  const DateOffsetResult.failed(DateOffsetError this.error) : date = null;

  /// The resulting calendar date.
  final DateTime? date;

  /// Why there is no [date].
  final DateOffsetError? error;
}

/// [start] plus or minus [amount] of [unit].
///
/// Days and weeks move by exact calendar days. Months and years move by
/// calendar months (a year is 12 months) and clamp to the month's end:
/// 31 Mar − 1 month is 28 Feb (29 in a leap year).
DateOffsetResult offsetDate({
  required DateTime start,
  required int amount,
  required DateUnit unit,
  required DateDirection direction,
}) {
  assert(amount >= 0, 'The amount is unsigned; direction carries the sign.');
  if (amount > maxDateAmount) {
    return const DateOffsetResult.failed(DateOffsetError.amountTooLarge);
  }
  final signed = direction == DateDirection.add ? amount : -amount;
  final result = switch (unit) {
    DateUnit.days => addDays(start, signed),
    DateUnit.weeks => addDays(start, signed * 7),
    DateUnit.months => addMonths(start, signed),
    DateUnit.years => addMonths(start, signed * 12),
  };
  return result == null
      ? const DateOffsetResult.failed(DateOffsetError.outOfRange)
      : DateOffsetResult.ok(result);
}
