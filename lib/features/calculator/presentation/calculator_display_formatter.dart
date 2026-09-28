import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/features/calculator/domain/expression_buffer.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// An expression as shown, and where the cursor positions fall in it.
typedef DisplayedExpression = ({String text, List<int> boundaries});

/// Turns calculator state into what the display shows and what screen
/// readers say, in the device region's number format (DEC-037).
final class CalculatorDisplayFormatter {
  /// Creates a formatter that writes numbers with [format] and words with
  /// [l10n].
  const CalculatorDisplayFormatter(this.format, this.l10n);

  /// The region's number format.
  final LocalizedNumberFormat format;

  /// The app's strings.
  final AppLocalizations l10n;

  /// [value] as shown: 12 significant digits, such as `12,34,567.5` or
  /// `1.5×10¹²`.
  String value(CalcValue value) =>
      format.formatCanonical(value.toDecimalString());

  /// [buffer] as shown. `boundaries[i]` is the text offset of the cursor
  /// position before unit `i`; the last entry is the text's length.
  ///
  /// Numbers are grouped as the region writes them. A negative value after
  /// the start is bracketed, so `5 − (−8)` doesn't read as `5−−8`. A long
  /// expression wraps after a binary operator, never inside a number that
  /// fits on a line: a zero-width space after each operator is the only
  /// place a line may break.
  DisplayedExpression expression(ExpressionBuffer buffer) {
    final units = buffer.units;
    final text = StringBuffer();
    final boundaries = <int>[];
    var i = 0;
    while (i < units.length) {
      final unit = units[i];
      if (_isNumberSymbol(unit)) {
        var end = i;
        while (end < units.length && _isNumberSymbol(units[end])) {
          end++;
        }
        final typed = units
            .sublist(i, end)
            .map((unit) => (unit as SymbolUnit).symbol)
            .join();
        final formatted = format.formatTypedWithOffsets(typed);
        final start = text.length;
        for (var k = 0; k < typed.length; k++) {
          boundaries.add(start + formatted.offsets[k]);
        }
        text.write(formatted.text);
        i = end;
        continue;
      }
      boundaries.add(text.length);
      text.write(switch (unit) {
        SymbolUnit(:final symbol) when _isBinaryOperatorAt(units, i) =>
          '$symbol$lineBreakOpportunity',
        SymbolUnit(:final symbol) => symbol,
        ValueUnit(value: final unitValue) => _valueInExpression(unitValue, i),
      });
      i++;
    }
    boundaries.add(text.length);
    return (text: text.toString(), boundaries: boundaries);
  }

  /// The zero-width space written after binary operators, where a long
  /// expression may wrap.
  static const String lineBreakOpportunity = '​';

  /// Whether the unit at [index] is an operator between two operands: not
  /// a minus sign at the start or after an operator or `(`.
  static bool _isBinaryOperatorAt(List<ExpressionUnit> units, int index) {
    final unit = units[index];
    if (unit is! SymbolUnit ||
        !CalculatorSymbols.operators.contains(unit.symbol)) {
      return false;
    }
    if (index == 0) return false;
    final previous = units[index - 1];
    return previous is ValueUnit ||
        previous is SymbolUnit &&
            !CalculatorSymbols.operators.contains(previous.symbol) &&
            previous.symbol != CalculatorSymbols.openBracket;
  }

  /// The cursor position (a unit index) nearest to text [offset] in
  /// [expression]. A tap exactly between two positions picks the later one,
  /// after the character tapped.
  static int cursorForOffset(DisplayedExpression expression, int offset) {
    final boundaries = expression.boundaries;
    var best = 0;
    for (var i = 1; i < boundaries.length; i++) {
      final distance = (boundaries[i] - offset).abs();
      if (distance <= (boundaries[best] - offset).abs()) best = i;
    }
    return best;
  }

  /// [buffer] as screen readers should say it, such as "5 plus 3".
  String spokenExpression(ExpressionBuffer buffer) {
    final words = <String>[];
    final number = StringBuffer();
    void endNumber() {
      if (number.isEmpty) return;
      words.add(format.formatTyped(number.toString()));
      number.clear();
    }

    for (final unit in buffer.units) {
      switch (unit) {
        case SymbolUnit(:final symbol) when _isNumberSymbol(unit):
          number.write(symbol);
        case SymbolUnit(:final symbol):
          endNumber();
          words.add(_spokenSymbol(symbol));
        case ValueUnit(value: final unitValue):
          endNumber();
          words.add(value(unitValue));
      }
    }
    endNumber();
    return words.join(' ');
  }

  /// The message for [error].
  String error(CalcError error) => switch (error) {
    CalcError.empty || CalcError.incomplete => l10n.errorIncomplete,
    CalcError.syntax => l10n.errorInvalid,
    CalcError.divisionByZero => l10n.errorDivisionByZero,
    CalcError.overflow => l10n.errorOverflow,
  };

  String _valueInExpression(CalcValue unitValue, int index) {
    final shown = value(unitValue);
    final negative = shown.startsWith(LocalizedNumberFormat.minusSign);
    return negative && index > 0 ? '($shown)' : shown;
  }

  String _spokenSymbol(String symbol) => switch (symbol) {
    CalculatorSymbols.plus => l10n.spokenPlus,
    CalculatorSymbols.minus => l10n.spokenMinus,
    CalculatorSymbols.times => l10n.spokenTimes,
    CalculatorSymbols.divide => l10n.spokenDividedBy,
    CalculatorSymbols.percent => l10n.spokenPercent,
    CalculatorSymbols.openBracket => l10n.spokenOpenBracket,
    CalculatorSymbols.closeBracket => l10n.spokenCloseBracket,
    _ => symbol,
  };

  static bool _isNumberSymbol(ExpressionUnit unit) =>
      unit is SymbolUnit &&
      (CalculatorSymbols.isDigit(unit.symbol) ||
          unit.symbol == CalculatorSymbols.decimalPoint);
}
