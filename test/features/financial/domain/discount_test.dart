import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/financial/domain/discount.dart';
import 'package:smart_calculator/features/financial/domain/validation.dart';

void main() {
  group('validateDiscountInputs', () {
    test('accepts sane inputs', () {
      expect(
        validateDiscountInputs(price: 1000, discountPercent: 20).hasErrors,
        isFalse,
      );
    });

    test('rejects a non-positive price', () {
      expect(
        validateDiscountInputs(price: 0, discountPercent: 20).price,
        FieldError.mustBePositive,
      );
    });

    test('rejects a negative discount', () {
      expect(
        validateDiscountInputs(
          price: 1000,
          discountPercent: -1,
        ).discountPercent,
        FieldError.mustBeNonNegative,
      );
    });

    test('accepts a 100% discount (a free item)', () {
      expect(
        validateDiscountInputs(
          price: 1000,
          discountPercent: 100,
        ).discountPercent,
        isNull,
      );
    });

    test('rejects a discount over 100%, never clamping', () {
      expect(
        validateDiscountInputs(
          price: 1000,
          discountPercent: 101,
        ).discountPercent,
        FieldError.tooLarge,
      );
    });
  });

  group('calculateDiscount', () {
    test('1000 at 20% off', () {
      final result = calculateDiscount(price: 1000, discountPercent: 20)!;
      expect(result.discountAmount, closeTo(200, 1e-9));
      expect(result.finalPrice, closeTo(800, 1e-9));
    });

    test('2499 at 15% off', () {
      final result = calculateDiscount(price: 2499, discountPercent: 15)!;
      expect(result.discountAmount, closeTo(374.85, 1e-9));
      expect(result.finalPrice, closeTo(2124.15, 1e-9));
    });

    test('a 100% discount makes the item free', () {
      final result = calculateDiscount(price: 1000, discountPercent: 100)!;
      expect(result.finalPrice, closeTo(0, 1e-9));
    });
  });
}
