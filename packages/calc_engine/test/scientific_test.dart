// Table-driven tests of CalcEngine.evaluate for Phase 5: the power
// operator, constants, and the scientific functions. Every case is its own
// test. Expected values were verified against the actual computed
// CalcValue.toDecimalString() before being written here (see DEC-047):
// floating-point noise from converting through degrees/radians is either
// absorbed by 12-significant-digit rounding, or (at an exact axis angle,
// where the mathematical answer is zero) snapped to exact zero.
import 'package:calc_engine/calc_engine.dart';
import 'package:test/test.dart';

const CalcEngine _engine = CalcEngine();

void _value(
  String input,
  String expected, {
  AngleMode angleMode = AngleMode.degrees,
  Map<String, CalcValue> variables = const {},
  bool exact = false,
  String? description,
}) {
  test(description ?? '$input = $expected', () {
    final result = _engine.evaluate(
      input,
      angleMode: angleMode,
      variables: variables,
    );
    expect(result, isA<CalcSuccess>(), reason: 'got $result');
    final value = (result as CalcSuccess).value;
    expect(value.toDecimalString(), expected);
    if (exact) expect(value.isExact, isTrue, reason: '$input should be exact');
  });
}

void _error(
  String input,
  CalcError error, {
  AngleMode angleMode = AngleMode.degrees,
  String? description,
}) {
  test(description ?? '"$input" → ${error.name}', () {
    expect(_engine.evaluate(input, angleMode: angleMode), CalcFailure(error));
  });
}

void main() {
  group('power: precedence (P-6)', () {
    _value('−3^2', '-9', description: 'unary minus binds looser than ^');
    _value('2^3^2', '512', description: '^ is right-associative');
    _value('2^-3', '0.125', exact: true);
    _value('−2^-3', '-0.125');
    _value('2^3', '8', exact: true);
    _value('(−3)^2', '9', description: 'parentheses override the default');
    _value('2^(3^2)', '512');
    _value('(2^3)^2', '64');
  });

  group('power: exact integers', () {
    _value('2^10', '1024', exact: true);
    _value('10^2', '100', exact: true);
    _value('2^0', '1', exact: true);
    _value('0^0', '1', exact: true, description: 'P-6');
    _value('0^5', '0', exact: true);
    _value('5^1', '5', exact: true);
    _value('1.5^2', '2.25', exact: true);
    _error('0^-1', CalcError.undefined);
    _error('0^-2', CalcError.undefined);
  });

  group('power: negative base, fractional exponent (P-6)', () {
    _value('(−8)^(1/3)', '-2', exact: true);
    _value('(−8)^(2/3)', '4', exact: true);
    _value('(−27)^(1/3)', '-3', exact: true);
    _value('(−8)^(−1/3)', '-0.5', exact: true);
    _error('(−4)^(1/2)', CalcError.undefined);
    _error('(−1)^0.5', CalcError.undefined);
    _error('(−4)^(1/4)', CalcError.undefined);
  });

  group('power: exact roots via a fractional exponent', () {
    _value('4^0.5', '2', exact: true);
    _value('9^(1/2)', '3', exact: true);
    _value('1^0.5', '1', exact: true);
    _value('0^0.5', '0', exact: true);
    _value('2^0.5', '1.4142135623730951'.substring(0, 13));
  });

  group('power: with percent, factorial and implied multiplication', () {
    _value(
      '2^2%',
      '1.01395947979',
      description: '% binds tighter than ^: 2^2% is 2^(2%) = 2^0.02',
    );
    _value(
      '2^3!',
      '64',
      description: '! binds tighter than ^: 2^3! is 2^(3!) = 2^6',
    );
    _value('2(3)^2', '18', description: 'implied × binds looser than ^');
  });

  group('factorial', () {
    _value('0!', '1', exact: true);
    _value('1!', '1', exact: true);
    _value('5!', '120', exact: true);
    _value('10!', '3628800', exact: true);
    _error('(−1)!', CalcError.undefined);
    _error('0.5!', CalcError.undefined);
    _error('100!', CalcError.overflow);
    _value('3!!', '720', description: '(3!)! = 6! = 720');
  });

  group('constants', () {
    _value('π', '3.14159265359');
    _value('e', '2.71828182846');
    _value('2π', '6.28318530718', description: 'implied × before a name');
    _value('π+π', '6.28318530718');
    _value('e^1', '2.71828182846');
  });

  group('trig: degrees (the default)', () {
    _value('sin(0)', '0');
    _value('sin(90)', '1');
    _value('sin(180)', '0');
    _value('sin(270)', '-1');
    _value('sin(360)', '0');
    _value('cos(0)', '1');
    _value('cos(90)', '0');
    _value('cos(180)', '-1');
    _value('cos(270)', '0');
    _value('sin(30)', '0.5');
    _value('cos(60)', '0.5');
    _value('tan(0)', '0');
    _value('tan(45)', '1');
    _value('tan(180)', '0');
    _error('tan(90)', CalcError.undefined);
    _error('tan(−90)', CalcError.undefined);
    _error('tan(270)', CalcError.undefined);
    _error('tan(450)', CalcError.undefined, description: '450 ≡ 90 (mod 180)');
  });

  group('trig: radians', () {
    _value('sin(π/2)', '1', angleMode: AngleMode.radians);
    _value('cos(π)', '-1', angleMode: AngleMode.radians);
    _value('tan(π/4)', '1', angleMode: AngleMode.radians);
    _value('sin(0)', '0', angleMode: AngleMode.radians);
  });

  group('inverse trig', () {
    _value('asin(1)', '90');
    _value('asin(0.5)', '30');
    _value('asin(0)', '0');
    _value('acos(1)', '0');
    _value('acos(0.5)', '60');
    _value('acos(−1)', '180');
    _value('atan(1)', '45');
    _value('atan(0)', '0');
    _error('asin(2)', CalcError.undefined);
    _error('asin(−2)', CalcError.undefined);
    _error('acos(2)', CalcError.undefined);
  });

  group('hyperbolic (never affected by angle mode)', () {
    _value('sinh(0)', '0');
    _value('cosh(0)', '1');
    _value('tanh(0)', '0');
    _value('sinh(0)', '0', angleMode: AngleMode.radians);
  });

  group('log and ln', () {
    _value('log(100)', '2');
    _value('log(1000)', '3');
    _value('log(1)', '0');
    _value('log(10)', '1');
    _value('ln(1)', '0');
    _error('log(0)', CalcError.undefined);
    _error('ln(0)', CalcError.undefined);
    _error('log(−5)', CalcError.undefined);
    _error('ln(−1)', CalcError.undefined);
  });

  group('sqrt', () {
    _value('sqrt(4)', '2', exact: true);
    _value('sqrt(9)', '3', exact: true);
    _value('sqrt(0)', '0', exact: true);
    _value('sqrt(0.25)', '0.5', exact: true);
    _value('sqrt(2)', '1.41421356237');
    _error('sqrt(−1)', CalcError.undefined);
    _error('sqrt(−4)', CalcError.undefined);
  });

  group('cbrt', () {
    _value('cbrt(8)', '2', exact: true);
    _value('cbrt(27)', '3', exact: true);
    _value('cbrt(−8)', '-2', exact: true, description: 'defined for negatives');
    _value('cbrt(−27)', '-3', exact: true);
    _value('cbrt(0)', '0', exact: true);
    _value('cbrt(2)', '1.25992104989');
  });

  group('abs', () {
    _value('abs(−5)', '5', exact: true);
    _value('abs(5)', '5', exact: true);
    _value('abs(0)', '0', exact: true);
    _value('abs(sqrt(2))', '1.41421356237');
  });

  group('function calls: syntax', () {
    _error('sin', CalcError.syntax, description: 'a function name needs (');
    _error('sin()', CalcError.syntax, description: 'no empty argument');
    _error('sin(5', CalcError.incomplete);
    _value('sin(sin(0))', '0', description: 'nested calls');
    _value('sin(90)+cos(0)', '2');
    _value('−sin(90)', '-1');
    _error(
      'sin(90)!',
      CalcError.undefined,
      description:
          'sin(90) is approximate, even though it is 1 exactly; '
          '! only accepts an exact whole number',
    );
  });

  group('"e" and "π" are always the constants, never a variable name', () {
    // A caller (the app inserts values as single/double letter variables,
    // such as a previous result) could in principle pass 'e' as a variable
    // name; the parser must still read it as Euler's number, since the app
    // relies on the engine never handing 'e' out as an ordinary name
    // (ExpressionBuffer skips it for exactly this reason).
    _value(
      'e',
      '2.71828182846',
      variables: {'e': CalcValue.fromInt(99)},
      description: 'a supplied "e" variable is ignored; the constant wins',
    );
    _value('a', '5', variables: {'a': CalcValue.fromInt(5)});
  });
}
