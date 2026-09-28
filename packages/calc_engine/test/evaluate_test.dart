// Table-driven tests of CalcEngine.evaluate: every case is its own test.
// Expected values are the canonical decimal strings of the exact result
// (CalcValue.toDecimalString, 12 significant digits).
import 'package:calc_engine/calc_engine.dart';
import 'package:test/test.dart';

const CalcEngine _engine = CalcEngine();

void _value(
  String input,
  String expected, {
  Map<String, CalcValue> variables = const {},
  String? description,
}) {
  test(description ?? '$input = $expected', () {
    final result = _engine.evaluate(input, variables: variables);
    expect(result, isA<CalcSuccess>(), reason: 'got $result');
    expect((result as CalcSuccess).value.toDecimalString(), expected);
  });
}

void _error(
  String input,
  CalcError error, {
  Map<String, CalcValue> variables = const {},
  String? description,
}) {
  test(description ?? '"$input" → ${error.name}', () {
    expect(_engine.evaluate(input, variables: variables), CalcFailure(error));
  });
}

CalcValue _fraction(int numerator, int denominator) =>
    CalcValue.fromInt(numerator) / CalcValue.fromInt(denominator);

void main() {
  final tenTo50 = '1${'0' * 50}';
  final tenTo49 = '1${'0' * 49}';
  final tenTo100 = '1${'0' * 100}';

  group('numbers', () {
    _value('0', '0');
    _value('7', '7');
    _value('42', '42');
    _value('007', '7');
    _value('.5', '0.5');
    _value('5.', '5');
    _value('0.1', '0.1');
    _value('3.14159', '3.14159');
    _value('12.50', '12.5');
    _value('1000000', '1000000');
    _value(' 12 ', '12');
    _value('0.000', '0');
    _value('999999999999', '999999999999');
    _value('123456789012', '123456789012');
    _value('1234567890123', '1.23456789012e12');
    _value('0.000001', '0.000001');
    _value('0.0000001', '1e-7');
    _value('0.00000123', '0.00000123');
  });

  group('malformed numbers and input', () {
    _error('1..2', CalcError.syntax);
    _error('1.2.3', CalcError.syntax);
    _error('.', CalcError.syntax);
    _error('', CalcError.empty);
    _error('   ', CalcError.empty);
    _error('1 2', CalcError.syntax);
    _error('12a', CalcError.syntax);
    _error('#', CalcError.syntax);
    _error(r'5$', CalcError.syntax);
    _error('1,000', CalcError.syntax);
  });

  group('addition and subtraction', () {
    _value('2+3', '5');
    _value('10−4', '6');
    _value('10-4', '6');
    _value('4−10', '-6');
    _value('0.5+0.25', '0.75');
    _value('1+2+3+4', '10');
    _value('100−1−1', '98');
    _value('0−0', '0');
    _value('−5+5', '0');
    _value('999999999999+1', '1e12');
    _value('0.1+0.7', '0.8');
    _value('1.005+0.005', '1.01');
  });

  group('multiplication and division', () {
    _value('6×7', '42');
    _value('6*7', '42');
    _value('8÷2', '4');
    _value('8/2', '4');
    _value('7÷2', '3.5');
    _value('1÷3', '0.333333333333');
    _value('2÷3', '0.666666666667');
    _value('1÷7', '0.142857142857');
    _value('10÷4', '2.5');
    _value('0.2×0.3', '0.06');
    _value('1.5×1.5', '2.25');
    _value('12345×6789', '83810205');
    _value('100÷8', '12.5');
    _value('0÷5', '0');
    _value('−6÷3', '-2');
    _value('6÷−3', '-2');
    _value('−6×−3', '18');
    _value('1÷8', '0.125');
    _value('22÷7', '3.14285714286');
    _value('1÷1000000', '0.000001');
    _value('1÷10000000', '1e-7');
    _value('1÷3×3', '1');
    _value('2÷3×3', '2');
    _value('10÷3×3', '10');
  });

  group('precedence and associativity', () {
    _value('2+3×4', '14');
    _value('2×3+4', '10');
    _value('2+3×4−5', '9');
    _value('10−4−3', '3');
    _value('100÷10÷2', '5');
    _value('2×3×4', '24');
    _value('8÷2×4', '16');
    _value('8÷(2×4)', '1');
    _value('1+2×3+4', '11');
    _value('10−2×3', '4');
    _value('2×3+4×5', '26');
    _value('20÷4+3×2', '11');
    _value('1−2+3', '2');
    _value('6÷3÷2', '1');
    _value('5+10÷2', '10');
    _value('2×−3+1', '-5');
  });

  group('brackets', () {
    _value('(2+3)×4', '20');
    _value('2×(3+4)', '14');
    _value('((2))', '2');
    _value('(((1+2)))', '3');
    _value('(1+2)×(3+4)', '21');
    _value('((1+2)×3)+4', '13');
    _value('2×(3+(4−1))', '12');
    _value('(10−(2+3))×2', '10');
    _value('(0.1+0.2)×10', '3');
    _value('(−5)', '-5');
    _value('−(2+3)', '-5');
    _value('(2+3)÷(1+4)', '1');
    _error('()', CalcError.syntax);
    _error('(', CalcError.incomplete);
    _error('(2+3', CalcError.incomplete);
    _error('2+3)', CalcError.syntax);
    _error(')', CalcError.syntax);
    _error('(()', CalcError.syntax);
    _error('((2)', CalcError.incomplete);
    _error('(+)', CalcError.syntax);
    _error('(5))', CalcError.syntax);
    _error('5()', CalcError.syntax);
  });

  group('implied multiplication', () {
    _value('2(3)', '6');
    _value('(2)(3)', '6');
    _value('(2)3', '6');
    _value('2(3)(4)', '24');
    _value('6÷2(1+2)', '9');
    _value('10%50', '5');
    _value('50%(2)', '1');
    _value('2(3+4)', '14');
    _value('(1+1)(1+1)(1+1)', '8');
    _value('3(−2)', '-6');
    _value('5(2)%', '0.1');
  });

  group('unary signs', () {
    _value('−5', '-5');
    _value('-5', '-5');
    _value('−−5', '5');
    _value('−−−5', '-5');
    _value('+5', '5');
    _value('+−5', '-5');
    _value('3×−2', '-6');
    _value('3−−2', '5');
    _value('3+−2', '1');
    _value('3++2', '5');
    _value('−0', '0');
    _value('−(−(2))', '2');
    _value('−5+3', '-2');
    _value('−0.5', '-0.5');
    _value('2÷−4', '-0.5');
  });

  group('smart percent (DEC-036)', () {
    _value('10%', '0.1');
    _value('50%', '0.5');
    _value('0%', '0');
    _value('100%', '1');
    _value('50+10%', '55');
    _value('50−10%', '45');
    _value('50×10%', '5');
    _value('50÷10%', '500');
    _value('200+10%+10%', '242');
    _value('100+(10)%', '110');
    _value('100+10%×2', '100.2');
    _value('50+−10%', '45');
    _value('10%%', '0.001');
    _value('(50+50)%', '1');
    _value('50+0%', '50');
    _value('1000−100%', '0');
    _value('20%×50', '10');
    _value('50%+50%', '0.75');
    _value('−10%', '-0.1');
    _value('80−25%', '60');
    _value('1200+18%', '1416');
    _value('100+12.5%', '112.5');
    _value('(100+10%)×2', '220');
    _value('10%×10%', '0.01');
    _value('5+5%%', '5.0025');
    _error('%', CalcError.syntax);
    _error('5+%', CalcError.syntax);
    _error('%5', CalcError.syntax);
    _error('(%)', CalcError.syntax);
  });

  group('exact arithmetic', () {
    _value('0.1+0.2', '0.3');
    _value('0.1+0.2−0.3', '0');
    _value('0.3−0.1', '0.2');
    _value('1.1×1.1', '1.21');
    _value('0.1×3', '0.3');
    _value('1÷10×10', '1');
    _value('2÷3+1÷3', '1');
    _value('1÷3+1÷3+1÷3', '1');
    _value('0.7+0.1', '0.8');
    _value('4.35×100', '435');
    _value('1.15×100', '115');
    _value('3×1.1', '3.3');
  });

  group('division by zero', () {
    _error('5÷0', CalcError.divisionByZero);
    _error('0÷0', CalcError.divisionByZero);
    _error('5÷(3−3)', CalcError.divisionByZero);
    _error('5÷0.0', CalcError.divisionByZero);
    _error('1÷(1−1)×0', CalcError.divisionByZero);
    _error('−5÷0', CalcError.divisionByZero);
    _error('5÷0%', CalcError.divisionByZero);
    _error('(1÷0)+1', CalcError.divisionByZero);
  });

  group('incomplete and invalid expressions', () {
    _error('5+', CalcError.incomplete);
    _error('5×', CalcError.incomplete);
    _error('5÷', CalcError.incomplete);
    _error('−', CalcError.incomplete);
    _error('+', CalcError.incomplete);
    _error('5−', CalcError.incomplete);
    _error('(5', CalcError.incomplete);
    _error('5(', CalcError.incomplete);
    _error('×5', CalcError.syntax);
    _error('÷5', CalcError.syntax);
    _error('*', CalcError.syntax);
    _error('5×÷3', CalcError.syntax);
    _error('5÷×3', CalcError.syntax);
    _error('abc', CalcError.syntax);
    _error('2×abc', CalcError.syntax);
    _error('5 5', CalcError.syntax);
    _error('5..5', CalcError.syntax);
    _error('5+()', CalcError.syntax);
  });

  group('very large and very small numbers', () {
    _value('999999999999×999999999999', '9.99999999998e23');
    _value('123456789×987654321', '1.21932631113e17');
    _value('10000000000×10000000000', '1e20');
    _value('$tenTo50×$tenTo49', '1e99', description: '10^50 × 10^49 = 1e99');
    _error(
      '$tenTo50×$tenTo50',
      CalcError.overflow,
      description: '10^50 × 10^50 overflows',
    );
    _error(
      '−$tenTo50×$tenTo50',
      CalcError.overflow,
      description: '−10^50 × 10^50 overflows',
    );
    _error(
      '($tenTo50×$tenTo50)÷10',
      CalcError.overflow,
      description: 'an intermediate result of 10^100 overflows',
    );
    _error(
      tenTo100,
      CalcError.overflow,
      description: 'the literal 10^100 overflows',
    );
    _value('1÷$tenTo50', '1e-50', description: '1 ÷ 10^50 = 1e-50');
    _value('0.5×0.00000002', '1e-8');
    _value('1÷3×1000000000000', '333333333333');
    _value('2÷3×1000000000000', '666666666667');
    _value('999999999999.6', '1e12');
    _value('0.9999999999995', '1');
    _value('−999999999999.6', '-1e12');
    _value('1.23456789012345', '1.23456789012');
    _value('0.000001234567890123', '0.00000123456789012');
    _value('0.00000099999999999999', '0.000001');
  });

  group('variables', () {
    _value('a', '5', variables: {'a': CalcValue.fromInt(5)});
    _value('a×3', '1', variables: {'a': _fraction(1, 3)});
    _value(
      'a+b',
      '3',
      variables: {'a': CalcValue.fromInt(1), 'b': CalcValue.fromInt(2)},
    );
    _value('2(a)', '8', variables: {'a': CalcValue.fromInt(4)});
    _value(
      '(a)b',
      '6',
      variables: {'a': CalcValue.fromInt(2), 'b': CalcValue.fromInt(3)},
    );
    _value('a%', '0.5', variables: {'a': CalcValue.fromInt(50)});
    _value('100+a%', '110', variables: {'a': CalcValue.fromInt(10)});
    _value('A', '1', variables: {'A': CalcValue.fromInt(1)});
    _error('x', CalcError.syntax);
    _error(
      'ab',
      CalcError.syntax,
      variables: {'a': CalcValue.fromInt(1), 'b': CalcValue.fromInt(2)},
    );
  });
}
