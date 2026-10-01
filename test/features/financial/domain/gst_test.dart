import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/financial/domain/gst.dart';
import 'package:smart_calculator/features/financial/domain/validation.dart';

void main() {
  group('validateGstInputs', () {
    test('accepts sane inputs', () {
      expect(
        validateGstInputs(amount: 1000, ratePercent: 18).hasErrors,
        isFalse,
      );
    });

    test('rejects a non-positive amount', () {
      expect(
        validateGstInputs(amount: 0, ratePercent: 18).amount,
        FieldError.mustBePositive,
      );
    });

    test('rejects a negative rate', () {
      expect(
        validateGstInputs(amount: 1000, ratePercent: -1).ratePercent,
        FieldError.mustBeNonNegative,
      );
    });

    test('rejects a rate over 100%', () {
      expect(
        validateGstInputs(
          amount: 1000,
          ratePercent: maxGstRatePercent + 1,
        ).ratePercent,
        FieldError.tooLarge,
      );
    });

    test('accepts a rate of exactly 100%', () {
      expect(
        validateGstInputs(
          amount: 1000,
          ratePercent: maxGstRatePercent,
        ).ratePercent,
        isNull,
      );
    });
  });

  group('calculateGst: exclusive', () {
    test('1000 at 18%', () {
      final result = calculateGst(
        amount: 1000,
        ratePercent: 18,
        mode: GstMode.exclusive,
      )!;
      expect(result.baseAmount, closeTo(1000, 1e-9));
      expect(result.gstAmount, closeTo(180, 1e-9));
      expect(result.totalAmount, closeTo(1180, 1e-9));
    });

    test('2500 at 5%', () {
      final result = calculateGst(
        amount: 2500,
        ratePercent: 5,
        mode: GstMode.exclusive,
      )!;
      expect(result.gstAmount, closeTo(125, 1e-9));
      expect(result.totalAmount, closeTo(2625, 1e-9));
    });
  });

  group('calculateGst: inclusive', () {
    test('1180 at 18% is the exact round-trip of the exclusive case', () {
      final result = calculateGst(
        amount: 1180,
        ratePercent: 18,
        mode: GstMode.inclusive,
      )!;
      expect(result.baseAmount, closeTo(1000, 1e-9));
      expect(result.gstAmount, closeTo(180, 1e-9));
      // The entered amount IS the total in inclusive mode.
      expect(result.totalAmount, closeTo(1180, 1e-9));
    });
  });

  group('splitIntraState', () {
    test('splits a GST amount evenly into CGST and SGST', () {
      final split = splitIntraState(180);
      expect(split.cgst, closeTo(90, 1e-9));
      expect(split.sgst, closeTo(90, 1e-9));
    });

    test('CGST + SGST always sum back to the original GST amount', () {
      for (final gst in [0.0, 1.0, 180.0, 999.99]) {
        final split = splitIntraState(gst);
        expect(split.cgst + split.sgst, closeTo(gst, 1e-9));
      }
    });
  });
}
