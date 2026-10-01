import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/financial/domain/tip.dart';
import 'package:smart_calculator/features/financial/domain/validation.dart';

void main() {
  group('validateTipInputs', () {
    test('accepts sane inputs', () {
      expect(
        validateTipInputs(bill: 1000, tipPercent: 10, splitCount: 1).hasErrors,
        isFalse,
      );
    });

    test('rejects a non-positive bill', () {
      expect(
        validateTipInputs(bill: 0, tipPercent: 10, splitCount: 1).bill,
        FieldError.mustBePositive,
      );
    });

    test('rejects a negative tip', () {
      expect(
        validateTipInputs(bill: 1000, tipPercent: -1, splitCount: 1).tipPercent,
        FieldError.mustBeNonNegative,
      );
    });

    test('rejects a tip over 100%', () {
      expect(
        validateTipInputs(
          bill: 1000,
          tipPercent: maxTipPercent + 1,
          splitCount: 1,
        ).tipPercent,
        FieldError.tooLarge,
      );
    });

    test('rejects a split count below 1', () {
      expect(
        validateTipInputs(bill: 1000, tipPercent: 10, splitCount: 0).splitCount,
        FieldError.mustBePositiveInteger,
      );
    });
  });

  group('calculateTip', () {
    test('1000 bill, 10% tip, split 4 ways', () {
      final result = calculateTip(bill: 1000, tipPercent: 10, splitCount: 4)!;
      expect(result.tipAmount, closeTo(100, 1e-9));
      expect(result.total, closeTo(1100, 1e-9));
      expect(result.perPerson, closeTo(275, 1e-9));
    });

    test('850 bill, 18% tip, split 3 ways: per-person rounding is not '
        'redistributed to force an exact sum (expected, not a bug)', () {
      final result = calculateTip(bill: 850, tipPercent: 18, splitCount: 3)!;
      expect(result.tipAmount, closeTo(153, 1e-9));
      expect(result.total, closeTo(1003, 1e-9));
      expect(result.perPerson, closeTo(334.3333333, 1e-6));
      final roundedPerPerson = double.parse(
        result.perPerson.toStringAsFixed(2),
      );
      expect(roundedPerPerson * 3, isNot(closeTo(result.total, 1e-9)));
    });

    test('a split count of 1 means no splitting', () {
      final result = calculateTip(bill: 1000, tipPercent: 10, splitCount: 1)!;
      expect(result.perPerson, closeTo(result.total, 1e-9));
    });
  });
}
