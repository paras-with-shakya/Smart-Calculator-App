import 'package:calc_engine/calc_engine.dart';
import 'package:test/test.dart';

void main() {
  final third = CalcValue.fromInt(1) / CalcValue.fromInt(3);

  group('parse', () {
    for (final (literal, expected) in [
      ('12', '12'),
      ('.5', '0.5'),
      ('5.', '5'),
      ('0.25', '0.25'),
      ('000.100', '0.1'),
    ]) {
      test('"$literal" is $expected', () {
        expect(CalcValue.parse(literal).toDecimalString(), expected);
      });
    }

    for (final literal in ['', '.', '-1', '1e5', '1,000', '1.2.3', ' 1']) {
      test('"$literal" is rejected', () {
        expect(() => CalcValue.parse(literal), throwsFormatException);
      });
    }
  });

  group('storage', () {
    for (final value in [
      third,
      -(CalcValue.fromInt(7) / CalcValue.fromInt(3)),
      CalcValue.zero,
      CalcValue.parse('123456789012345678901234567890.5'),
    ]) {
      test('${value.toStorageString()} round-trips exactly', () {
        expect(CalcValue.tryParseStorage(value.toStorageString()), value);
      });
    }

    test('an integer is stored without a denominator', () {
      expect(CalcValue.fromInt(-42).toStorageString(), '-42');
    });

    for (final text in ['abc', '1/0', '1/-2', '', '1.5', '/3', '3/']) {
      test('"$text" is not a stored value', () {
        expect(CalcValue.tryParseStorage(text), isNull);
      });
    }
  });

  group('arithmetic', () {
    final two = CalcValue.fromInt(2);
    final three = CalcValue.fromInt(3);

    test('+ − × ÷ and negation are exact', () {
      expect((two + three).toDecimalString(), '5');
      expect((two - three).toDecimalString(), '-1');
      expect((two * three).toDecimalString(), '6');
      expect(third * three, CalcValue.fromInt(1));
      expect((-two).toDecimalString(), '-2');
    });

    test('dividing by zero throws, so callers must check isZero', () {
      expect(() => two / CalcValue.zero, throwsArgumentError);
      expect(CalcValue.zero.isZero, isTrue);
      expect(two.isZero, isFalse);
    });

    test('isTooLarge starts at 10^100', () {
      expect(CalcValue.parse('9' * 100).isTooLarge, isFalse);
      expect(CalcValue.parse('1${'0' * 100}').isTooLarge, isTrue);
      expect((-CalcValue.parse('1${'0' * 100}')).isTooLarge, isTrue);
    });

    test('equal values are equal and hash alike, whatever their form', () {
      expect(CalcValue.parse('0.50'), CalcValue.fromInt(1) / two);
      expect(
        CalcValue.parse('0.50').hashCode,
        (CalcValue.fromInt(1) / two).hashCode,
      );
    });
  });

  group('toDecimalString', () {
    test('rounds to the requested significant digits', () {
      expect(third.toDecimalString(significantDigits: 4), '0.3333');
      expect(
        (CalcValue.fromInt(2) / CalcValue.fromInt(3)).toDecimalString(
          significantDigits: 1,
        ),
        '0.7',
      );
    });

    test('rounds halves away from zero', () {
      expect(CalcValue.parse('2.5').toDecimalString(significantDigits: 1), '3');
      expect(
        (-CalcValue.parse('2.5')).toDecimalString(significantDigits: 1),
        '-3',
      );
    });

    test('rejects fewer than one significant digit', () {
      expect(
        () => third.toDecimalString(significantDigits: 0),
        throwsRangeError,
      );
    });
  });
}
