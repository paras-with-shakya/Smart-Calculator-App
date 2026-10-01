import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/financial/domain/simple_interest.dart';
import 'package:smart_calculator/features/financial/domain/validation.dart';

void main() {
  group('validateSimpleInterestInputs', () {
    test('accepts sane inputs', () {
      expect(
        validateSimpleInterestInputs(
          principal: 10000,
          ratePercent: 5,
          years: 2,
        ).hasErrors,
        isFalse,
      );
    });

    test('rejects a non-positive principal', () {
      expect(
        validateSimpleInterestInputs(
          principal: 0,
          ratePercent: 5,
          years: 2,
        ).principal,
        FieldError.mustBePositive,
      );
    });

    test('rejects a negative rate', () {
      expect(
        validateSimpleInterestInputs(
          principal: 10000,
          ratePercent: -1,
          years: 2,
        ).ratePercent,
        FieldError.mustBeNonNegative,
      );
    });

    test('rejects a non-positive time', () {
      expect(
        validateSimpleInterestInputs(
          principal: 10000,
          ratePercent: 5,
          years: 0,
        ).years,
        FieldError.mustBePositive,
      );
    });

    test('rejects a time over 100 years', () {
      expect(
        validateSimpleInterestInputs(
          principal: 10000,
          ratePercent: 5,
          years: maxSimpleInterestYears + 1,
        ).years,
        FieldError.tooLarge,
      );
    });
  });

  group('calculateSimpleInterest', () {
    test('10000 at 5% for 2 years', () {
      final result = calculateSimpleInterest(
        principal: 10000,
        ratePercent: 5,
        years: 2,
      )!;
      expect(result.interest, closeTo(1000, 1e-9));
      expect(result.totalAmount, closeTo(11000, 1e-9));
    });

    test('25000 at 7.5% for 3 years', () {
      final result = calculateSimpleInterest(
        principal: 25000,
        ratePercent: 7.5,
        years: 3,
      )!;
      expect(result.interest, closeTo(5625, 1e-9));
      expect(result.totalAmount, closeTo(30625, 1e-9));
    });

    test('a fractional time is allowed', () {
      final result = calculateSimpleInterest(
        principal: 10000,
        ratePercent: 10,
        years: 0.5,
      )!;
      expect(result.interest, closeTo(500, 1e-9));
    });
  });
}
