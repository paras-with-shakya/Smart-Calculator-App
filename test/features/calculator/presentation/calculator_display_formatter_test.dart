import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/features/calculator/domain/expression_buffer.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_display_formatter.dart';

import '../../../helpers/test_app.dart';

const String zwsp = CalculatorDisplayFormatter.lineBreakOpportunity;

/// A buffer of typed symbols, one unit per character.
ExpressionBuffer typed(String symbols) => ExpressionBuffer.of([
  for (final symbol in symbols.split('')) SymbolUnit(symbol),
]);

void main() {
  final indian = CalculatorDisplayFormatter(
    LocalizedNumberFormat('en_IN'),
    l10n,
  );
  final german = CalculatorDisplayFormatter(
    LocalizedNumberFormat('de_DE'),
    l10n,
  );
  final eight = CalcValue.fromInt(8);

  group('expression text', () {
    test('groups numbers the region way', () {
      expect(indian.expression(typed('1234567.5')).text, '12,34,567.5');
      expect(german.expression(typed('1234.5')).text, '1.234,5');
    });

    test('marks a line break only after binary operators', () {
      expect(indian.expression(typed('5×−3+(−2)')).text, '5×$zwsp−3+$zwsp(−2)');
      expect(indian.expression(typed('−5')).text, '−5');
    });

    test('shows values, bracketing a negative one after the start', () {
      final negative = -eight;
      final buffer = ExpressionBuffer.of([
        ValueUnit(negative),
        const SymbolUnit(CalculatorSymbols.minus),
        ValueUnit(negative),
      ]);

      expect(indian.expression(buffer).text, '−8−$zwsp(−8)');
    });

    test('maps every cursor position into the text', () {
      // 1 , 2 3 4 + ZWSP 5
      final shown = indian.expression(typed('1234+5'));

      expect(shown.text, '1,234+${zwsp}5');
      expect(shown.boundaries, [0, 2, 3, 4, 5, 7, 8]);
    });

    test('a value is one cursor step', () {
      final shown = indian.expression(
        ExpressionBuffer.of([
          ValueUnit(CalcValue.fromInt(1234)),
          const SymbolUnit(CalculatorSymbols.times),
          const SymbolUnit('2'),
        ]),
      );

      expect(shown.text, '1,234×${zwsp}2');
      expect(shown.boundaries, [0, 5, 7, 8]);
    });
  });

  group('cursor for a tapped offset', () {
    final shown = indian.expression(typed('1234+5'));

    const cases = {0: 0, 1: 1, 2: 1, 3: 2, 5: 4, 6: 5, 7: 5, 8: 6, 99: 6};
    cases.forEach((offset, cursor) {
      test('offset $offset → cursor $cursor', () {
        expect(
          CalculatorDisplayFormatter.cursorForOffset(shown, offset),
          cursor,
        );
      });
    });
  });

  group('spoken expression', () {
    test('says operators as words', () {
      expect(
        indian.spokenExpression(typed('(12+3)×4÷2−1%')),
        '${l10n.spokenOpenBracket} 12 ${l10n.spokenPlus} 3 '
        '${l10n.spokenCloseBracket} ${l10n.spokenTimes} 4 '
        '${l10n.spokenDividedBy} 2 ${l10n.spokenMinus} 1 '
        '${l10n.spokenPercent}',
      );
    });

    test('says numbers and values as shown', () {
      final buffer = ExpressionBuffer.of([
        ...typed('1234567').units,
        const SymbolUnit(CalculatorSymbols.plus),
        ValueUnit(eight),
      ]);

      expect(indian.spokenExpression(buffer), '12,34,567 ${l10n.spokenPlus} 8');
    });
  });

  test('values use 12 significant digits and the region format', () {
    expect(
      indian.value(CalcValue.fromInt(1) / CalcValue.fromInt(3)),
      '0.333333333333',
    );
    expect(german.value(CalcValue.parse('1234.5')), '1.234,5');
    expect(indian.value(-eight), '−8');
  });

  test('every error has a message', () {
    expect(indian.error(CalcError.incomplete), l10n.errorIncomplete);
    expect(indian.error(CalcError.syntax), l10n.errorInvalid);
    expect(indian.error(CalcError.divisionByZero), l10n.errorDivisionByZero);
    expect(indian.error(CalcError.overflow), l10n.errorOverflow);
  });
  group('scientific expressions', () {
    ExpressionBuffer units(List<String> symbols) =>
        ExpressionBuffer.of([for (final symbol in symbols) SymbolUnit(symbol)]);

    test('show symbols, constants and function openers as typed', () {
      final buffer = units(['2', '^', '3', '!', '×', 'π', '+', 'sin(', '3']);

      expect(
        indian.expression(buffer).text,
        '2^${zwsp}3!×$zwsp'
        'π+$zwsp'
        'sin(3',
      );
    });

    test('show the root functions with their signs', () {
      expect(indian.expression(units(['sqrt(', '9', ')'])).text, '√(9)');
      expect(indian.expression(units(['cbrt(', '8'])).text, '∛(8');
    });

    test('a minus after ^ or a function opener is a sign, not a break', () {
      expect(indian.expression(units(['2', '^', '−', '3'])).text, '2^$zwsp−3');
      expect(indian.expression(units(['sin(', '−', '3'])).text, 'sin(−3');
    });

    test('keep one cursor position per unit', () {
      final shown = indian.expression(units(['sqrt(', '9', ')']));

      expect(shown.boundaries, [0, 2, 3, 4]);
    });

    test('are spoken in words', () {
      expect(
        indian.spokenExpression(units(['2', '^', '3', '!'])),
        '2 to the power of 3 factorial',
      );
      expect(
        indian.spokenExpression(units(['sqrt(', 'π', ')'])),
        'square root of pi close bracket',
      );
      expect(
        indian.spokenExpression(units(['sin(', '3', '0', ')', '+', 'e'])),
        'sine of 30 close bracket plus e',
      );
    });

    test('every function opener has a spoken name', () {
      for (final function in CalcFunction.values) {
        final spoken = indian.spokenExpression(
          units([CalculatorSymbols.functionOpener(function)]),
        );
        expect(spoken, endsWith(' of'), reason: function.name);
      }
    });

    test('name every scientific error', () {
      expect(indian.error(CalcError.undefined), isNotEmpty);
      expect(indian.error(CalcError.overflow), isNotEmpty);
    });
  });
}
