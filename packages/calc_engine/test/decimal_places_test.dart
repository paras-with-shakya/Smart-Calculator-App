import 'package:calc_engine/calc_engine.dart';
import 'package:test/test.dart';

CalcValue exact(String expression) {
  final result = const CalcEngine().evaluate(expression);
  expect(result, isA<CalcSuccess>(), reason: expression);
  return (result as CalcSuccess).value;
}

String places(String expression, int decimalPlaces) =>
    exact(expression).toDecimalString(decimalPlaces: decimalPlaces);

void main() {
  group('rounding the fraction to N places (exact values)', () {
    test('repeating fractions', () {
      expect(places('1÷3', 4), '0.3333');
      expect(places('2÷3', 2), '0.67');
      expect(places('2÷3', 6), '0.666667');
      expect(places('1÷7', 8), '0.14285714');
    });

    test('half rounds away from zero', () {
      expect(places('0.5', 0), '1');
      expect(places('1.5', 0), '2');
      expect(places('2.5', 0), '3');
      expect(places('−0.5', 0), '−1'.replaceAll('−', '-'));
      expect(places('0.125', 2), '0.13');
      expect(places('−0.125', 2), '-0.13');
      expect(places('5÷4', 1), '1.3');
    });

    test('trailing zeros are not padded', () {
      expect(places('1÷4', 4), '0.25');
      expect(places('0.1', 8), '0.1');
      expect(places('3', 4), '3');
      expect(places('2.50', 3), '2.5');
    });

    test('a whole number is never changed', () {
      expect(places('987654+123456', 2), '1111110');
      expect(places('123456789', 0), '123456789');
      expect(places('999999999999', 2), '999999999999');
    });

    test('a value that rounds to zero is 0, never -0', () {
      expect(places('0.001', 2), '0');
      expect(places('−0.001', 2), '0');
      expect(places('1÷3', 0), '0');
      expect(places('−1÷3', 0), '0');
    });

    test('carries into the whole part', () {
      expect(places('0.999', 2), '1');
      expect(places('9.995', 2), '10');
      expect(places('−9.995', 2), '-10');
    });

    test('still follows the significant-digit and scientific rules', () {
      // 12 significant digits remain the ceiling.
      expect(places('123456789012÷100+0.456', 2), '1234567890.58');
      expect(exact('10^15').toDecimalString(decimalPlaces: 2), '1e15');
      // Zero stays zero.
      expect(places('0', 2), '0');
    });

    test('zero places and many places', () {
      expect(places('3.14159', 0), '3');
      expect(places('3.14159', 10), '3.14159');
    });
  });

  group('approximate values round the digits that are shown', () {
    test('irrational results', () {
      expect(places('sqrt(2)', 4), '1.4142');
      expect(places('π', 2), '3.14');
      expect(places('π', 8), '3.14159265');
    });

    test('a double that is not exact in binary still rounds as written', () {
      // 0.285 is 0.28499999999999998 as a double; the digits shown are
      // 0.285, which round half away from zero to 0.29.
      expect(places('sin(30)×0.57', 2), '0.29');
      expect(places('0.285', 2), '0.29');
    });

    test('a degree result that snaps to an exact value', () {
      expect(places('sin(30)', 2), '0.5');
      expect(places('cos(60)', 2), '0.5');
    });
  });

  group('the default is unchanged', () {
    test('without decimalPlaces nothing rounds the fraction', () {
      expect(exact('1÷3').toDecimalString(), '0.333333333333');
      expect(exact('π').toDecimalString(), '3.14159265359');
    });

    test('a negative number of places is rejected', () {
      expect(
        () => exact('1').toDecimalString(decimalPlaces: -1),
        throwsRangeError,
      );
    });
  });
}
