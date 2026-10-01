import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/financial/domain/percentage.dart';
import 'package:smart_calculator/features/financial/domain/validation.dart';

void main() {
  group('percent of', () {
    test('15% of 200 is 30', () {
      expect(calculatePercentOf(x: 15, y: 200), closeTo(30, 1e-9));
    });

    test('rejects a non-positive base', () {
      expect(validatePercentOfInputs(x: 15, y: 0).y, FieldError.mustBePositive);
    });

    test('rejects a negative percentage', () {
      expect(
        validatePercentOfInputs(x: -1, y: 200).x,
        FieldError.mustBeNonNegative,
      );
    });
  });

  group('what percent', () {
    test('50 is 25% of 200', () {
      expect(calculateWhatPercent(x: 50, y: 200), closeTo(25, 1e-9));
    });

    test('rejects a non-positive base (avoids division by zero)', () {
      expect(
        validateWhatPercentInputs(x: 50, y: 0).y,
        FieldError.mustBePositive,
      );
    });
  });

  group('change by', () {
    test('increasing 200 by 15% gives 230', () {
      expect(
        calculateChangeBy(
          x: 15,
          y: 200,
          direction: PercentageDirection.increase,
        ),
        closeTo(230, 1e-9),
      );
    });

    test('decreasing 200 by 15% gives 170', () {
      expect(
        calculateChangeBy(
          x: 15,
          y: 200,
          direction: PercentageDirection.decrease,
        ),
        closeTo(170, 1e-9),
      );
    });

    test('an increase has no upper cap', () {
      expect(
        validateChangeByInputs(
          x: 500,
          y: 200,
          direction: PercentageDirection.increase,
        ).x,
        isNull,
      );
    });

    test('a decrease over 100% is rejected, mirroring discount', () {
      expect(
        validateChangeByInputs(
          x: maxDecreasePercent + 1,
          y: 200,
          direction: PercentageDirection.decrease,
        ).x,
        FieldError.tooLarge,
      );
    });

    test('a decrease of exactly 100% is allowed (goes to zero)', () {
      expect(
        validateChangeByInputs(
          x: maxDecreasePercent,
          y: 200,
          direction: PercentageDirection.decrease,
        ).x,
        isNull,
      );
      expect(
        calculateChangeBy(
          x: maxDecreasePercent,
          y: 200,
          direction: PercentageDirection.decrease,
        ),
        closeTo(0, 1e-9),
      );
    });
  });
}
