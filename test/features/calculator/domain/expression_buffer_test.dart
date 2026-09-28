import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/calculator/domain/expression_buffer.dart';

import '../../../helpers/expression_text.dart';

final CalcValue third = CalcValue.fromInt(1) / CalcValue.fromInt(3);
final CalcValue half = CalcValue.fromInt(1) / CalcValue.fromInt(2);

/// Types [keys] into [start], one edit per character:
/// digits, `.`, `+ − × ÷`, `%`, `(`, `)`, `b` (the smart bracket key),
/// `<` (backspace), `L`/`R` (cursor left/right), `v` (one third as a value)
/// and `w` (one half as a value).
ExpressionBuffer type(
  String keys, [
  ExpressionBuffer start = ExpressionBuffer.empty,
]) {
  var buffer = start;
  for (final key in keys.split('')) {
    buffer = switch (key) {
      '.' => buffer.insertDecimalPoint(),
      '+' || '−' || '×' || '÷' => buffer.insertOperator(key),
      '%' => buffer.insertPercent(),
      '(' => buffer.insertOpenBracket(),
      ')' => buffer.insertCloseBracket(),
      'b' => buffer.insertBracket(),
      '<' => buffer.backspace(),
      'L' => buffer.withCursor(buffer.cursor - 1),
      'R' => buffer.withCursor(buffer.cursor + 1),
      'v' => buffer.insertValue(third),
      'w' => buffer.insertValue(half),
      _ when CalculatorSymbols.isDigit(key) => buffer.insertDigit(key),
      _ => throw ArgumentError('Unknown key: $key'),
    };
  }
  return buffer;
}

/// Checks that typing each key sequence shows the expected buffer.
void expectTyping(Map<String, String> cases) {
  cases.forEach((keys, expected) {
    test('"$keys" → "$expected"', () {
      expect(show(type(keys)), expected);
    });
  });
}

void main() {
  group('numbers', () {
    expectTyping({
      '': '|',
      '5': '5|',
      '100': '100|',
      '00': '0|',
      '05': '5|',
      '0.05': '0.05|',
      '0.0': '0.0|',
      '.': '0.|',
      '.5': '0.5|',
      '5..': '5.|',
      '5.5.': '5.5|',
      '5+.': '5+0.|',
      '5+0': '5+0|',
      '5+00': '5+0|',
      '5+05': '5+5|',
      '123456789012345': '123456789012345|',
      '1234567890123456': '123456789012345|',
      '123456789012345+6': '123456789012345+6|',
    });
  });

  group('operators', () {
    expectTyping({
      '+': '|',
      '×': '|',
      '÷': '|',
      '−': '−|',
      '−−': '−|',
      '−+': '−|',
      '5+': '5+|',
      '5+×': '5×|',
      '5+−': '5−|',
      '5−×': '5×|',
      '5×−': '5×−|',
      '5×−−': '5×−|',
      '5×−+': '5+|',
      '5÷−×': '5×|',
      '5×−3': '5×−3|',
      '(+': '(|',
      '(−': '(−|',
      '(−×': '(−|',
      '5.+': '5.+|',
      '5%+': '5%+|',
      '(5)×': '(5)×|',
    });
  });

  group('percent', () {
    expectTyping({
      '%': '|',
      '5%': '5%|',
      '5%%': '5%|',
      '5+%': '5+|',
      '(%': '(|',
      '(5)%': '(5)%|',
      '5%3': '5%×3|',
      '5%.': '5%×0.|',
      '5%(': '5%×(|',
    });
  });

  group('brackets', () {
    expectTyping({
      '(': '(|',
      ')': '|',
      '()': '(|',
      '(5': '(5|',
      '(5)': '(5)|',
      '(5))': '(5)|',
      '(5+)': '(5+|',
      '((5)': '((5)|',
      '5(': '5×(|',
      '(5)(': '(5)×(|',
      '(5)3': '(5)×3|',
      '(5).': '(5)×0.|',
    });
  });

  group('the smart bracket key', () {
    expectTyping({
      'b': '(|',
      '5b': '5×(|',
      'b5b': '(5)|',
      'b5+b': '(5+(|',
      'bb5bb': '((5))|',
      'b5bb': '(5)×(|',
      'b5bbb': '(5)×((|',
    });
  });

  group('backspace', () {
    expectTyping({
      '<': '|',
      '5<': '|',
      '12<': '1|',
      '5+<': '5|',
      '5(<': '5×|',
      '(5)<': '(5|',
      '0.<': '0|',
    });
  });

  group('editing at the cursor', () {
    expectTyping({
      '12L3': '13|2',
      '5LL': '|5',
      '5RR': '5|',
      '5L0': '|5',
      '5L.': '0.|5',
      '12L.': '1.|2',
      '1.2L.': '1.|2',
      '0.5LL3': '3|.5',
      '0.5LLL3': '3|0.5',
      '5L−': '−|5',
      '5L×': '|5',
      '5+3LL<': '|+3',
      '(5)L)': '(5|)',
      '((5)L)': '((5)|)',
      '123456789012345L6': '12345678901234|5',
    });
  });

  group('values', () {
    expectTyping({
      'v': '{1/3}|',
      'v5': '{1/3}×5|',
      '5v': '5×{1/3}|',
      'vw': '{1/3}×{1/2}|',
      'v(': '{1/3}×(|',
      'v.': '{1/3}×0.|',
      'v%': '{1/3}%|',
      'v+': '{1/3}+|',
      'v+×': '{1/3}×|',
      '−v': '−{1/3}|',
      '(5)v': '(5)×{1/3}|',
      'v<': '|',
      'v5<<': '{1/3}|',
      'vL+': '|{1/3}',
      'vL−': '−|{1/3}',
      // A number typed before a value stays one number, apart from it.
      'vL5': '5|×{1/3}',
      'vL56': '56|×{1/3}',
      'vL.': '0.|×{1/3}',
      'vL05': '5|×{1/3}',
      '5Lv': '{1/3}|×5',
      '(5)LLLv': '{1/3}|×(5)',
      'wLv': '{1/3}|×{1/2}',
    });
  });

  test('stops accepting input at the unit limit', () {
    final full = type('1+' * 50);
    expect(full.units, hasLength(ExpressionBuffer.maxUnits));

    expect(full.insertDigit('1'), same(full));
    expect(full.insertOpenBracket(), same(full));
    expect(full.insertValue(third), same(full));
    expect(show(full.backspace()), '${'1+' * 49}1|');
  });

  test('an implied × that would pass the limit is refused whole', () {
    final almostFull = type('${'1+' * 48}(1)');
    expect(almostFull.units, hasLength(ExpressionBuffer.maxUnits - 1));

    expect(almostFull.insertDigit('2'), same(almostFull));
    expect(almostFull.insertDecimalPoint(), same(almostFull));
    expect(
      almostFull.insertPercent().units,
      hasLength(ExpressionBuffer.maxUnits),
    );
  });

  group('closing brackets', () {
    test('counts the brackets still open', () {
      expect(type('').openBrackets, 0);
      expect(type('((5+3').openBrackets, 2);
      expect(type('((5)').openBrackets, 1);
    });

    test('closes every open bracket, with the cursor at the end', () {
      expect(show(type('((5+3LL').withBracketsClosed), '((5+3))|');
      expect(show(type('5+3').withBracketsClosed), '5+3|');
    });
  });

  group('plain numbers', () {
    const plain = ['5', '5.', '0.25', '−5', 'v', '−v'];
    const notPlain = ['', '−', '5+3', '5%', '(5)', 'v+', 'v5', '−(5'];

    for (final keys in plain) {
      test('"$keys" is a plain number', () {
        expect(type(keys).isPlainNumber, isTrue);
      });
    }
    for (final keys in notPlain) {
      test('"$keys" is not a plain number', () {
        expect(type(keys).isPlainNumber, isFalse);
      });
    }
  });

  group('engine input', () {
    test('typed symbols pass through as they are', () {
      final input = type('(5+3)×2÷−4%').toEngineInput();

      expect(input.expression, '(5+3)×2÷−4%');
      expect(input.variables, isEmpty);
    });

    test('values become bracketed letter variables', () {
      final input = type('v+w').toEngineInput();

      expect(input.expression, '(a)+(b)');
      expect(input.variables, {'a': third, 'b': half});
    });

    test('variables after z continue with two letters', () {
      final units = <ExpressionUnit>[
        for (var i = 0; i < 28; i++) ...[
          if (i > 0) const SymbolUnit(CalculatorSymbols.plus),
          ValueUnit(CalcValue.fromInt(i)),
        ],
      ];
      final input = ExpressionBuffer.of(units).toEngineInput();

      expect(input.variables.keys.skip(24), ['y', 'z', 'aa', 'ab']);
      expect(input.variables['ab'], CalcValue.fromInt(27));
    });

    test('evaluates exactly', () {
      final input = type('v×3').toEngineInput();

      expect(
        const CalcEngine().evaluate(
          input.expression,
          variables: input.variables,
        ),
        CalcSuccess(CalcValue.fromInt(1)),
      );
    });

    test('two values next to each other multiply', () {
      // Only reachable by deleting the × between them at the cursor.
      final buffer = type('v×wL<');
      final input = buffer.toEngineInput();

      expect(show(buffer), '{1/3}|{1/2}');
      expect(
        const CalcEngine().evaluate(
          input.expression,
          variables: input.variables,
        ),
        CalcSuccess(CalcValue.fromInt(1) / CalcValue.fromInt(6)),
      );
    });
  });

  group('the buffer as a value', () {
    test('is equal to a buffer with the same units and cursor', () {
      expect(type('5+3'), type('5+3'));
      expect(type('5+3').hashCode, type('5+3').hashCode);
      expect(type('5+3'), isNot(type('5+3L')));
      expect(type('5+3'), isNot(type('5+4')));
    });

    test('clamps the cursor', () {
      expect(type('53').withCursor(-4).cursor, 0);
      expect(type('53').withCursor(9).cursor, 2);
      expect(ExpressionBuffer.of([const SymbolUnit('5')], cursor: 7).cursor, 1);
    });

    test('cannot be changed from outside', () {
      expect(
        () => type('5').units.add(const SymbolUnit('6')),
        throwsUnsupportedError,
      );
    });

    test('describes itself with the cursor', () {
      expect(type('5+3L').toString(), 'ExpressionBuffer(5+|3)');
    });
  });
}
