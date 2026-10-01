import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/financial/domain/compound_interest.dart';
import 'package:smart_calculator/features/financial/domain/validation.dart';

void main() {
  group('CompoundingFrequency.periodsPerYear', () {
    test('matches the four standard compounding frequencies', () {
      expect(CompoundingFrequency.annual.periodsPerYear, 1);
      expect(CompoundingFrequency.semiAnnual.periodsPerYear, 2);
      expect(CompoundingFrequency.quarterly.periodsPerYear, 4);
      expect(CompoundingFrequency.monthly.periodsPerYear, 12);
    });
  });

  group('validateCompoundInterestInputs', () {
    test('accepts sane inputs', () {
      expect(
        validateCompoundInterestInputs(
          principal: 10000,
          ratePercent: 10,
          years: 2,
        ).hasErrors,
        isFalse,
      );
    });

    test('rejects a non-positive principal', () {
      expect(
        validateCompoundInterestInputs(
          principal: 0,
          ratePercent: 10,
          years: 2,
        ).principal,
        FieldError.mustBePositive,
      );
    });

    test('rejects a non-positive time', () {
      expect(
        validateCompoundInterestInputs(
          principal: 10000,
          ratePercent: 10,
          years: 0,
        ).years,
        FieldError.mustBePositive,
      );
    });

    test('rejects a time over 100 years', () {
      expect(
        validateCompoundInterestInputs(
          principal: 10000,
          ratePercent: 10,
          years: maxCompoundInterestYears + 1,
        ).years,
        FieldError.tooLarge,
      );
    });
  });

  group('calculateCompoundInterest', () {
    test('10000 at 10% annual for 2 years', () {
      final result = calculateCompoundInterest(
        principal: 10000,
        ratePercent: 10,
        years: 2,
        frequency: CompoundingFrequency.annual,
      )!;
      expect(result.totalAmount, closeTo(12100, 1e-6));
      expect(result.interest, closeTo(2100, 1e-6));
    });

    test('10000 at 10% semi-annual for 1 year', () {
      final result = calculateCompoundInterest(
        principal: 10000,
        ratePercent: 10,
        years: 1,
        frequency: CompoundingFrequency.semiAnnual,
      )!;
      expect(result.totalAmount, closeTo(11025, 1e-6));
      expect(result.interest, closeTo(1025, 1e-6));
    });

    test('more frequent compounding yields more interest, all else equal', () {
      double interestFor(CompoundingFrequency frequency) =>
          calculateCompoundInterest(
            principal: 10000,
            ratePercent: 10,
            years: 5,
            frequency: frequency,
          )!.interest;

      final annual = interestFor(CompoundingFrequency.annual);
      final quarterly = interestFor(CompoundingFrequency.quarterly);
      final monthly = interestFor(CompoundingFrequency.monthly);
      expect(quarterly, greaterThan(annual));
      expect(monthly, greaterThan(quarterly));
    });
  });
}
