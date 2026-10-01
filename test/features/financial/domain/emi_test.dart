import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/financial/domain/emi.dart';
import 'package:smart_calculator/features/financial/domain/validation.dart';

void main() {
  group('tenureMonthsFrom', () {
    test('months pass through, rounded', () {
      expect(tenureMonthsFrom(value: 24, unit: TenureUnit.months), 24);
    });

    test('years convert to months', () {
      expect(tenureMonthsFrom(value: 2, unit: TenureUnit.years), 24);
    });

    test('a fractional year rounds to the nearest month', () {
      // 2.33 years = 27.96 months -> 28.
      expect(tenureMonthsFrom(value: 2.33, unit: TenureUnit.years), 28);
    });
  });

  group('validateEmiInputs', () {
    test('accepts sane inputs', () {
      final errors = validateEmiInputs(
        principal: 100000,
        ratePercent: 10,
        tenureMonths: 12,
      );
      expect(errors.hasErrors, isFalse);
    });

    test('rejects a non-positive principal', () {
      expect(
        validateEmiInputs(
          principal: 0,
          ratePercent: 10,
          tenureMonths: 12,
        ).principal,
        FieldError.mustBePositive,
      );
    });

    test('rejects a negative rate', () {
      expect(
        validateEmiInputs(
          principal: 100000,
          ratePercent: -1,
          tenureMonths: 12,
        ).ratePercent,
        FieldError.mustBeNonNegative,
      );
    });

    test('accepts a zero rate (promotional loans)', () {
      expect(
        validateEmiInputs(
          principal: 100000,
          ratePercent: 0,
          tenureMonths: 12,
        ).ratePercent,
        isNull,
      );
    });

    test('rejects a rate over the sane bound', () {
      expect(
        validateEmiInputs(
          principal: 100000,
          ratePercent: maxEmiRatePercent + 0.01,
          tenureMonths: 12,
        ).ratePercent,
        FieldError.tooLarge,
      );
    });

    test('accepts a rate exactly at the sane bound', () {
      expect(
        validateEmiInputs(
          principal: 100000,
          ratePercent: maxEmiRatePercent,
          tenureMonths: 12,
        ).ratePercent,
        isNull,
      );
    });

    test('rejects a non-positive tenure', () {
      expect(
        validateEmiInputs(
          principal: 100000,
          ratePercent: 10,
          tenureMonths: 0,
        ).tenureMonths,
        FieldError.mustBePositive,
      );
    });

    test('rejects a tenure over 600 months', () {
      expect(
        validateEmiInputs(
          principal: 100000,
          ratePercent: 10,
          tenureMonths: maxEmiTenureMonths + 1,
        ).tenureMonths,
        FieldError.tooLarge,
      );
    });

    test('accepts a tenure of exactly 600 months', () {
      expect(
        validateEmiInputs(
          principal: 100000,
          ratePercent: 10,
          tenureMonths: maxEmiTenureMonths,
        ).tenureMonths,
        isNull,
      );
    });
  });

  group('calculateEmi', () {
    test('a 0% loan splits the principal evenly', () {
      final result = calculateEmi(
        principal: 120000,
        ratePercent: 0,
        tenureMonths: 12,
      )!;
      expect(result.monthlyEmi, closeTo(10000, 1e-9));
      expect(result.totalInterest, closeTo(0, 1e-9));
      expect(result.totalPayment, closeTo(120000, 1e-9));
    });

    test('one month at 12% annual is exact: P x (1+r)', () {
      final result = calculateEmi(
        principal: 10000,
        ratePercent: 12,
        tenureMonths: 1,
      )!;
      expect(result.monthlyEmi, closeTo(10100, 1e-6));
    });

    test('two months at 12% annual shows the exact rounding discrepancy '
        'between the rounded EMI and the unrounded total (the displayed '
        'total is derived from the unrounded EMI, not 2x the rounded EMI)', () {
      final result = calculateEmi(
        principal: 10000,
        ratePercent: 12,
        tenureMonths: 2,
      )!;
      expect(result.monthlyEmi, closeTo(5075.1243781, 1e-6));
      expect(result.totalPayment, closeTo(10150.2487562, 1e-6));
      // The rounded-for-display EMI (5075.12) x 2 is 10150.24, NOT the
      // 10150.25 the unrounded total rounds to -- confirming the total
      // must come from the unrounded value, never re-derived from text.
      expect(
        double.parse(result.monthlyEmi.toStringAsFixed(2)) * 2,
        isNot(
          closeTo(double.parse(result.totalPayment.toStringAsFixed(2)), 1e-9),
        ),
      );
    });

    test('the classic P=100000, 10% annual, 12 months reference example '
        '(a commonly published EMI-calculator worked example) matches to '
        'the cent', () {
      final result = calculateEmi(
        principal: 100000,
        ratePercent: 10,
        tenureMonths: 12,
      )!;
      expect(result.monthlyEmi, closeTo(8791.59, 0.01));
    });

    test('an extreme but rule-legal rate still returns a finite result', () {
      final result = calculateEmi(
        principal: 100000,
        ratePercent: maxEmiRatePercent,
        tenureMonths: maxEmiTenureMonths,
      );
      expect(result, isNotNull);
      expect(result!.monthlyEmi.isFinite, isTrue);
      expect(result.totalPayment.isFinite, isTrue);
    });
  });
}
