/// Calendar-date arithmetic (DEC-053).
///
/// A date here is a *calendar date*, not an instant: a `DateTime.utc` at
/// midnight. Nothing in this file reads a time zone or a time of day, so a
/// daylight-saving change can never move a result by a day. Anything that
/// arrives as a local `DateTime` (a date picker, the clock) goes through
/// [calendarDate] first, which keeps only its year, month and day.
library;

/// The earliest year the calculator accepts a result in.
const int minYear = 1;

/// The latest year the calculator accepts a result in.
const int maxYear = 9999;

/// The calendar date of [value]: its year, month and day as seen on the
/// wall (in whatever zone [value] is in), as midnight UTC.
DateTime calendarDate(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

/// Whether [year] is a leap year (Gregorian: every 4th year, except
/// century years not divisible by 400).
bool isLeapYear(int year) =>
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

/// How many days [month] (1–12) of [year] has.
int daysInMonth(int year, int month) => switch (month) {
  2 => isLeapYear(year) ? 29 : 28,
  4 || 6 || 9 || 11 => 30,
  _ => 31,
};

/// Whether [date] is within the years the calculator supports.
bool isSupportedDate(DateTime date) =>
    date.year >= minYear && date.year <= maxYear;

/// [date] moved by [months] (negative moves back), or `null` if the result
/// would fall outside [minYear]..[maxYear].
///
/// The day of the month is kept where the target month has it, and clamped
/// to the target month's last day where it doesn't: 31 Jan + 1 month is
/// 28 Feb (29 in a leap year), and 29 Feb 2024 + 12 months is 28 Feb 2025.
DateTime? addMonths(DateTime date, int months) {
  assert(date.isUtc, 'Calendar dates are UTC; use calendarDate().');
  final total = date.year * 12 + (date.month - 1) + months;
  // Range-check before dividing: `~/` truncates toward zero, which is only
  // wrong for negative totals, and every negative total is out of range.
  if (total < minYear * 12 || total > maxYear * 12 + 11) return null;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = daysInMonth(year, month);
  return DateTime.utc(year, month, date.day > lastDay ? lastDay : date.day);
}

/// [date] moved by [days] (negative moves back), or `null` if the result
/// would fall outside [minYear]..[maxYear].
DateTime? addDays(DateTime date, int days) {
  assert(date.isUtc, 'Calendar dates are UTC; use calendarDate().');
  final result = DateTime.utc(date.year, date.month, date.day + days);
  return isSupportedDate(result) ? result : null;
}

/// The whole days from [from] to [to] (negative if [to] is earlier).
int daysBetween(DateTime from, DateTime to) {
  assert(from.isUtc && to.isUtc, 'Calendar dates are UTC.');
  return to.difference(from).inDays;
}
