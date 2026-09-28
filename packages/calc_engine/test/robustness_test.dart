import 'dart:math';

import 'package:calc_engine/calc_engine.dart';
import 'package:test/test.dart';

const CalcEngine _engine = CalcEngine();

/// The canonical form of CalcValue.toDecimalString.
final RegExp _canonical = RegExp(r'^-?\d+(\.\d+)?(e-?\d+)?$');

void main() {
  test('random input never throws, and every result is a value or a typed '
      'error with a canonical decimal string', () {
    final random = Random(20260928);
    const alphabet = '0123456789..+−×÷-*/%%(()) a';
    for (var run = 0; run < 20000; run++) {
      final length = random.nextInt(24);
      final input = String.fromCharCodes([
        for (var i = 0; i < length; i++)
          alphabet.codeUnitAt(random.nextInt(alphabet.length)),
      ]);
      final result = _engine.evaluate(input);
      switch (result) {
        case CalcSuccess(:final value):
          final text = value.toDecimalString();
          expect(text, matches(_canonical), reason: '"$input" gave $text');
          expect(text, isNot(anyOf('-0', 'NaN', 'Infinity')));
        case CalcFailure():
          break;
      }
    }
  });

  test('brackets nested past the limit are a syntax error, not a crash', () {
    final deep = '${'(' * 5000}1${')' * 5000}';
    expect(_engine.evaluate(deep), const CalcFailure(CalcError.syntax));
  });

  test('a long chain of unary signs is a syntax error, not a crash', () {
    expect(
      _engine.evaluate('${'−' * 5000}1'),
      const CalcFailure(CalcError.syntax),
    );
  });

  test('moderate nesting still works', () {
    final nested = '${'(' * 50}2${')' * 50}';
    expect(_engine.evaluate(nested), CalcSuccess(CalcValue.fromInt(2)));
  });

  test('input longer than the token limit is a syntax error', () {
    final long = List.filled(3000, '1').join('+');
    expect(_engine.evaluate(long), const CalcFailure(CalcError.syntax));
  });

  test('a long but allowed chain evaluates', () {
    final chain = List.filled(400, '1').join('+');
    expect(_engine.evaluate(chain), CalcSuccess(CalcValue.fromInt(400)));
  });
}
