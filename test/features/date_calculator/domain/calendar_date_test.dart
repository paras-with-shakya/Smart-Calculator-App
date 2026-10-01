import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/date_calculator/domain/calendar_date.dart';
import 'package:smart_calculator/features/date_calculator/domain/date_difference.dart';
import 'package:smart_calculator/features/date_calculator/domain/date_offset.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

DateTime? months(DateTime date, int n) => addMonths(date, n);

void main() {
  group('leap years', () {
    test('follow the Gregorian rule', () {
      expect(isLeapYear(2024), isTrue);
      expect(isLeapYear(2000), isTrue);
      expect(isLeapYear(1900), isFalse);
      expect(isLeapYear(2100), isFalse);
      expect(isLeapYear(2023), isFalse);
      expect(isLeapYear(1600), isTrue);
    });

    test('February has 29 days only in a leap year', () {
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2025, 2), 28);
      expect(daysInMonth(1900, 2), 28);
      expect(daysInMonth(2000, 2), 29);
    });

    test('every month has the right length', () {
      expect(
        [for (var m = 1; m <= 12; m++) daysInMonth(2025, m)],
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
      );
    });
  });

  group('addMonths clamps to the month end', () {
    test('31 Jan + 1 month', () {
      expect(months(d(2025, 1, 31), 1), d(2025, 2, 28));
      expect(months(d(2024, 1, 31), 1), d(2024, 2, 29));
    });

    test('31 Mar - 1 month', () {
      expect(months(d(2025, 3, 31), -1), d(2025, 2, 28));
      expect(months(d(2024, 3, 31), -1), d(2024, 2, 29));
    });

    test('30-day months', () {
      expect(months(d(2025, 3, 31), 1), d(2025, 4, 30));
      expect(months(d(2025, 5, 31), -1), d(2025, 4, 30));
    });

    test('29 Feb + whole years', () {
      expect(months(d(2024, 2, 29), 12), d(2025, 2, 28));
      expect(months(d(2024, 2, 29), 48), d(2028, 2, 29));
      expect(months(d(2024, 2, 29), -12), d(2023, 2, 28));
    });

    test('crosses year boundaries both ways', () {
      expect(months(d(2025, 11, 15), 3), d(2026, 2, 15));
      expect(months(d(2025, 1, 15), -1), d(2024, 12, 15));
      expect(months(d(2025, 1, 31), -13), d(2023, 12, 31));
      expect(months(d(2025, 6, 10), 0), d(2025, 6, 10));
    });

    test('rejects results outside years 1-9999', () {
      expect(months(d(9999, 12, 31), 1), isNull);
      expect(months(d(9999, 12, 31), 0), d(9999, 12, 31));
      expect(months(d(1, 1, 31), -1), isNull);
      expect(months(d(1, 2, 28), -1), d(1, 1, 28));
      expect(months(d(2025, 1, 1), -1000000), isNull);
      expect(months(d(2025, 1, 1), 1000000), isNull);
    });
  });

  group('addDays', () {
    test('crosses month and year ends', () {
      expect(addDays(d(2025, 12, 31), 1), d(2026, 1, 1));
      expect(addDays(d(2026, 1, 1), -1), d(2025, 12, 31));
      expect(addDays(d(2024, 2, 28), 1), d(2024, 2, 29));
      expect(addDays(d(2025, 2, 28), 1), d(2025, 3, 1));
      expect(addDays(d(2025, 1, 1), 365), d(2026, 1, 1));
      expect(addDays(d(2024, 1, 1), 366), d(2025, 1, 1));
    });

    test('rejects results outside years 1-9999', () {
      expect(addDays(d(1, 1, 1), -1), isNull);
      expect(addDays(d(1, 1, 1), 0), d(1, 1, 1));
      expect(addDays(d(9999, 12, 31), 1), isNull);
    });
  });

  group('daylight saving never moves a day', () {
    // US: clocks change 2026-03-08 and 2026-11-01; EU: 2026-03-29 and
    // 2026-10-25. The domain never sees a time zone (it works on UTC
    // midnights), so these pin the results; the local-time inputs a picker
    // produces are covered by the calendarDate group below.
    for (final (from, to, days) in [
      (d(2026, 3, 7), d(2026, 3, 9), 2),
      (d(2026, 3, 8), d(2026, 3, 9), 1),
      (d(2026, 10, 31), d(2026, 11, 2), 2),
      (d(2026, 11, 1), d(2026, 11, 2), 1),
      (d(2026, 3, 28), d(2026, 3, 30), 2),
      (d(2026, 10, 24), d(2026, 10, 26), 2),
      (d(2026, 3, 1), d(2026, 4, 1), 31),
      (d(2026, 10, 1), d(2026, 11, 30), 60),
    ]) {
      test('$from to $to is $days days', () {
        expect(daysBetween(from, to), days);
        expect(dateDifference(from, to).totalDays, days);
        expect(addDays(from, days), to);
      });
    }

    test('a year across a DST change is still 365 days', () {
      expect(daysBetween(d(2026, 3, 1), d(2027, 3, 1)), 365);
    });
  });

  group('calendarDate keeps only year, month and day', () {
    test('drops the time of day, even late at night', () {
      expect(calendarDate(DateTime(2026, 3, 8, 23, 30)), d(2026, 3, 8));
      expect(calendarDate(DateTime(2026, 3, 8, 0, 0, 1)), d(2026, 3, 8));
      expect(calendarDate(DateTime(2026, 3, 8, 2, 30)), d(2026, 3, 8));
    });

    test('is UTC, so the arithmetic asserts accept it', () {
      expect(calendarDate(DateTime(2026, 11, 1, 1, 30)).isUtc, isTrue);
    });

    test('reads the wall date of a UTC instant, not a converted one', () {
      expect(calendarDate(DateTime.utc(2026, 3, 8, 23, 59)), d(2026, 3, 8));
    });
  });

  group('dateDifference', () {
    void expectGap(
      DateTime a,
      DateTime b,
      int years,
      int months,
      int days,
      int totalDays,
    ) {
      final gap = dateDifference(a, b);
      expect(
        (gap.years, gap.months, gap.days, gap.totalDays),
        (years, months, days, totalDays),
        reason: '$a to $b',
      );
    }

    test('the same date is all zeros', () {
      expectGap(d(2025, 5, 5), d(2025, 5, 5), 0, 0, 0, 0);
    });

    test('whole years', () {
      expectGap(d(2025, 1, 1), d(2026, 1, 1), 1, 0, 0, 365);
      expectGap(d(2024, 1, 1), d(2025, 1, 1), 1, 0, 0, 366);
    });

    test('month ends agree with addMonths', () {
      expectGap(d(2025, 1, 31), d(2025, 2, 28), 0, 1, 0, 28);
      expectGap(d(2025, 1, 31), d(2025, 3, 1), 0, 1, 1, 29);
      expectGap(d(2025, 1, 31), d(2025, 4, 30), 0, 3, 0, 89);
      expectGap(d(2024, 1, 31), d(2024, 2, 29), 0, 1, 0, 29);
    });

    test('leap day', () {
      expectGap(d(2024, 2, 29), d(2025, 2, 28), 1, 0, 0, 365);
      expectGap(d(2024, 2, 29), d(2025, 3, 1), 1, 0, 1, 366);
      expectGap(d(2024, 2, 29), d(2028, 2, 29), 4, 0, 0, 1461);
      expectGap(d(2024, 2, 28), d(2024, 3, 1), 0, 0, 2, 2);
    });

    test('a mixed gap', () {
      expectGap(d(2020, 3, 15), d(2025, 6, 20), 5, 3, 5, 1923);
      expectGap(d(2025, 1, 15), d(2025, 3, 10), 0, 1, 23, 54);
    });

    test('is the same in either order', () {
      final forward = dateDifference(d(2020, 3, 15), d(2025, 6, 20));
      final backward = dateDifference(d(2025, 6, 20), d(2020, 3, 15));
      expect(
        (backward.years, backward.months, backward.days, backward.totalDays),
        (forward.years, forward.months, forward.days, forward.totalDays),
      );
    });

    test('weeks and the days after them', () {
      final gap = dateDifference(d(2025, 1, 1), d(2025, 1, 23));
      expect((gap.weeks, gap.daysAfterWeeks), (3, 1));
      expect(dateDifference(d(2025, 1, 1), d(2025, 1, 1)).weeks, 0);
    });

    test('totalMonths includes the years', () {
      expect(dateDifference(d(2020, 1, 1), d(2022, 4, 1)).totalMonths, 27);
    });

    test('spans the supported range', () {
      final gap = dateDifference(d(1, 1, 1), d(9999, 12, 31));
      expect((gap.years, gap.months, gap.days), (9998, 11, 30));
    });
  });

  group('the two tools agree (property tests)', () {
    // A fixed grid, not random: every start day of two years (one leap) and
    // a spread of month counts, so month ends and Feb 29 are all hit.
    final starts = [for (var i = 0; i < 731; i++) addDays(d(2023, 1, 1), i)!];

    test('dateDifference(a, a + k months) is exactly k months', () {
      for (final a in starts) {
        for (final k in [0, 1, 2, 3, 11, 12, 13, 24, 25, 47, 48, 120]) {
          final b = addMonths(a, k)!;
          final gap = dateDifference(a, b);
          expect(
            (gap.totalMonths, gap.days),
            (k, 0),
            reason: '$a + $k months = $b',
          );
        }
      }
    });

    test('anchor + days always lands on the later date', () {
      for (final a in starts) {
        for (final n in [
          0,
          1,
          27,
          28,
          29,
          30,
          31,
          32,
          59,
          60,
          365,
          366,
          1000,
        ]) {
          final b = addDays(a, n)!;
          final gap = dateDifference(a, b);
          expect(gap.totalDays, n);
          expect(gap.days, inInclusiveRange(0, 30));
          final anchor = addMonths(a, gap.totalMonths)!;
          expect(anchor.isAfter(b), isFalse);
          expect(addDays(anchor, gap.days), b, reason: '$a to $b');
          // The months are the largest that fit.
          expect(addMonths(a, gap.totalMonths + 1)!.isAfter(b), isTrue);
        }
      }
    });

    test('adding then subtracting days is the identity', () {
      for (final a in starts) {
        for (final n in [1, 7, 31, 365, 10000]) {
          expect(addDays(addDays(a, n)!, -n), a);
        }
      }
    });
  });

  group('offsetDate', () {
    DateTime? run(
      DateTime start,
      int amount,
      DateUnit unit,
      DateDirection direction,
    ) => offsetDate(
      start: start,
      amount: amount,
      unit: unit,
      direction: direction,
    ).date;

    test('days and weeks', () {
      expect(run(d(2025, 1, 1), 90, .days, .add), d(2025, 4, 1));
      expect(run(d(2025, 1, 1), 2, .weeks, .add), d(2025, 1, 15));
      expect(run(d(2025, 3, 1), 1, .days, .subtract), d(2025, 2, 28));
      expect(run(d(2024, 3, 1), 1, .days, .subtract), d(2024, 2, 29));
    });

    test('months and years clamp to the month end', () {
      expect(run(d(2025, 8, 31), 6, .months, .subtract), d(2025, 2, 28));
      expect(run(d(2025, 1, 31), 1, .months, .add), d(2025, 2, 28));
      expect(run(d(2024, 2, 29), 1, .years, .add), d(2025, 2, 28));
      expect(run(d(2024, 2, 29), 4, .years, .add), d(2028, 2, 29));
    });

    test('zero changes nothing', () {
      for (final unit in DateUnit.values) {
        expect(run(d(2025, 5, 5), 0, unit, .add), d(2025, 5, 5));
      }
    });

    test('too large an amount is its own error', () {
      final result = offsetDate(
        start: d(2025, 1, 1),
        amount: maxDateAmount + 1,
        unit: .days,
        direction: .add,
      );
      expect(result.error, DateOffsetError.amountTooLarge);
      expect(result.date, isNull);
    });

    test('the largest amount is allowed, and may still be out of range', () {
      final days = offsetDate(
        start: d(2025, 1, 1),
        amount: maxDateAmount,
        unit: .days,
        direction: .add,
      );
      expect(days.date, isNotNull);
      final years = offsetDate(
        start: d(2025, 1, 1),
        amount: maxDateAmount,
        unit: .years,
        direction: .add,
      );
      expect(years.error, DateOffsetError.outOfRange);
    });

    test('results outside years 1-9999 are out of range', () {
      expect(
        offsetDate(
          start: d(9999, 12, 31),
          amount: 1,
          unit: .days,
          direction: .add,
        ).error,
        DateOffsetError.outOfRange,
      );
      expect(
        offsetDate(
          start: d(1, 1, 1),
          amount: 1,
          unit: .months,
          direction: .subtract,
        ).error,
        DateOffsetError.outOfRange,
      );
    });
  });
}
