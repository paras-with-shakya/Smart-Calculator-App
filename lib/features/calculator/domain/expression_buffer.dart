import 'package:calc_engine/calc_engine.dart';

/// The symbols an expression is typed with. They are also what the engine
/// reads.
abstract final class CalculatorSymbols {
  /// Addition.
  static const String plus = '+';

  /// Subtraction and unary minus (U+2212).
  static const String minus = '−';

  /// Multiplication.
  static const String times = '×';

  /// Division.
  static const String divide = '÷';

  /// Postfix percent.
  static const String percent = '%';

  /// Opening bracket.
  static const String openBracket = '(';

  /// Closing bracket.
  static const String closeBracket = ')';

  /// Decimal point, whatever the region shows (the display localizes it).
  static const String decimalPoint = '.';

  /// The binary operators.
  static const Set<String> operators = {plus, minus, times, divide};

  /// Whether [symbol] is a digit, 0-9.
  static bool isDigit(String symbol) =>
      symbol.length == 1 &&
      symbol.codeUnitAt(0) >= 0x30 &&
      symbol.codeUnitAt(0) <= 0x39;
}

/// One unit of an expression: what one key press adds, and what backspace
/// removes.
sealed class ExpressionUnit {
  const ExpressionUnit();
}

/// A typed symbol: a digit, the decimal point, an operator, `%` or a
/// bracket.
final class SymbolUnit extends ExpressionUnit {
  /// Creates a unit for [symbol].
  const SymbolUnit(this.symbol);

  /// One of [CalculatorSymbols], or a digit.
  final String symbol;

  @override
  bool operator ==(Object other) =>
      other is SymbolUnit && other.symbol == symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() => symbol;
}

/// An exact value inserted as a whole, such as the previous result or the
/// memory. It keeps full precision (`1÷3` stays exactly one third), and
/// backspace removes it in one step.
final class ValueUnit extends ExpressionUnit {
  /// Creates a unit holding [value].
  const ValueUnit(this.value);

  /// The exact value.
  final CalcValue value;

  @override
  bool operator ==(Object other) => other is ValueUnit && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '{${value.toStorageString()}}';
}

/// The expression being typed: units and a cursor between them.
///
/// Every edit returns a new buffer and follows the calculator's input rules,
/// so the expression stays sensible:
///
/// - no leading zeros, and at most one decimal point per number;
/// - a new operator replaces the previous one, except that `−` after `×`
///   or `÷` starts a negative number;
/// - a closing bracket only when a bracket is open;
/// - `×` is inserted when a number, a bracket or a value follows `)`, `%` or
///   a value, and between a value and a number typed next to it, so two
///   operands never look like one number.
///
/// Edits the rules reject return the same buffer.
final class ExpressionBuffer {
  const ExpressionBuffer._(this.units, this.cursor);

  /// A buffer with [units] and the cursor at [cursor] (the end by default).
  factory ExpressionBuffer.of(List<ExpressionUnit> units, {int? cursor}) =>
      ExpressionBuffer._(
        List.unmodifiable(units),
        (cursor ?? units.length).clamp(0, units.length),
      );

  /// The empty buffer.
  static const ExpressionBuffer empty = ExpressionBuffer._([], 0);

  /// The most units a buffer holds; further input is ignored.
  static const int maxUnits = 100;

  /// The most digits one number may have.
  static const int maxDigitsPerNumber = 15;

  /// The units, in order.
  final List<ExpressionUnit> units;

  /// The cursor, as the number of units before it (0 to `units.length`).
  final int cursor;

  /// Whether nothing has been typed.
  bool get isEmpty => units.isEmpty;

  /// Whether the buffer is a single number with nothing to calculate: digits
  /// and a point, or a single value, optionally after a minus sign.
  bool get isPlainNumber {
    final unsigned = _symbolAt(0) == CalculatorSymbols.minus
        ? units.skip(1).toList()
        : units;
    return unsigned.isNotEmpty &&
        (unsigned.length == 1 && unsigned.single is ValueUnit ||
            unsigned.every(_isNumberSymbol));
  }

  /// How many brackets are open at the end of the expression.
  int get openBrackets => _depthBefore(units.length);

  /// This buffer with every open bracket closed, and the cursor at the end.
  ExpressionBuffer get withBracketsClosed => ExpressionBuffer.of([
    ...units,
    for (var i = 0; i < openBrackets; i++)
      const SymbolUnit(CalculatorSymbols.closeBracket),
  ]);

  /// This buffer as locale-neutral text, purely for display (a history
  /// entry's label): every value unit is written as its own decimal text,
  /// not as a reusable variable. Never re-parsed — the same way a history
  /// entry is "reused" through its exact [ValueUnit.value], not by
  /// reconstructing the expression that produced it (mirrors how
  /// continuing after `=` acts on the exact result, not the expression
  /// text it came from).
  String toCanonicalText() => units
      .map(
        (unit) => switch (unit) {
          SymbolUnit(:final symbol) => symbol,
          ValueUnit(:final value) => value.toDecimalString(),
        },
      )
      .join();

  /// The text and variables to evaluate. Each value becomes a letter-only
  /// variable, so it is evaluated exactly. The variable is bracketed, so a
  /// value next to another operand multiplies it, as it would after `)`.
  ({String expression, Map<String, CalcValue> variables}) toEngineInput() {
    final text = StringBuffer();
    final variables = <String, CalcValue>{};
    for (final unit in units) {
      switch (unit) {
        case SymbolUnit(:final symbol):
          text.write(symbol);
        case ValueUnit(:final value):
          final name = _variableName(variables.length);
          variables[name] = value;
          text.write('($name)');
      }
    }
    return (expression: text.toString(), variables: variables);
  }

  /// This buffer with the cursor at [index] (clamped).
  ExpressionBuffer withCursor(int index) =>
      ExpressionBuffer._(units, index.clamp(0, units.length));

  /// Types [digit] (0-9).
  ExpressionBuffer insertDigit(String digit) {
    assert(CalculatorSymbols.isDigit(digit), 'Not a digit: $digit');
    if (_numberAroundCursor.where(_isDigitUnit).length >= maxDigitsPerNumber) {
      return this;
    }
    final before = _numberBeforeCursor;
    if (before.length == 1 && before.single == const SymbolUnit('0')) {
      // A lone leading zero is replaced, never followed by a digit.
      return digit == '0' ? this : _replaceBefore(1, [SymbolUnit(digit)]);
    }
    if (digit == '0' && before.isEmpty && _isDigitUnitAt(cursor)) return this;
    return _insertNumberPart([SymbolUnit(digit)]);
  }

  /// Types the decimal point.
  ExpressionBuffer insertDecimalPoint() {
    if (_numberAroundCursor.contains(_point)) return this;
    return _insertNumberPart([
      if (_numberBeforeCursor.isEmpty) const SymbolUnit('0'),
      _point,
    ]);
  }

  /// Types the binary operator [operator] (one of
  /// [CalculatorSymbols.operators]).
  ExpressionBuffer insertOperator(String operator) {
    assert(
      CalculatorSymbols.operators.contains(operator),
      'Not an operator: $operator',
    );
    final isMinus = operator == CalculatorSymbols.minus;
    final previous = _symbolAt(cursor - 1);
    if (previous == null && cursor == 0 ||
        previous == CalculatorSymbols.openBracket) {
      return isMinus
          ? _insert([const SymbolUnit(CalculatorSymbols.minus)])
          : this;
    }
    if (previous != null && CalculatorSymbols.operators.contains(previous)) {
      final multiplicative =
          previous == CalculatorSymbols.times ||
          previous == CalculatorSymbols.divide;
      if (isMinus && multiplicative) {
        return _insert([const SymbolUnit(CalculatorSymbols.minus)]);
      }
      if (previous == CalculatorSymbols.minus && _isUnaryMinusAt(cursor - 1)) {
        final beforeMinus = _symbolAt(cursor - 2);
        final afterMultiplicative =
            beforeMinus == CalculatorSymbols.times ||
            beforeMinus == CalculatorSymbols.divide;
        if (isMinus || !afterMultiplicative) return this;
        return _replaceBefore(2, [SymbolUnit(operator)]);
      }
      return _replaceBefore(1, [SymbolUnit(operator)]);
    }
    return _insert([SymbolUnit(operator)]);
  }

  /// Types `%`, which must follow a number, `)` or a value.
  ExpressionBuffer insertPercent() {
    if (!_endsWithOperand ||
        _symbolAt(cursor - 1) == CalculatorSymbols.percent) {
      return this;
    }
    return _insert([const SymbolUnit(CalculatorSymbols.percent)]);
  }

  /// Types `(`, with an implied `×` after an operand.
  ExpressionBuffer insertOpenBracket() => _endsWithOperand
      ? _insert([
          const SymbolUnit(CalculatorSymbols.times),
          const SymbolUnit(CalculatorSymbols.openBracket),
        ])
      : _insert([const SymbolUnit(CalculatorSymbols.openBracket)]);

  /// Types `)`, if a bracket is open and an operand comes before it.
  ExpressionBuffer insertCloseBracket() => _canCloseBracket
      ? _insert([const SymbolUnit(CalculatorSymbols.closeBracket)])
      : this;

  /// The single bracket key: closes a bracket when one is open and an
  /// operand comes before the cursor, otherwise opens one.
  ExpressionBuffer insertBracket() =>
      _canCloseBracket ? insertCloseBracket() : insertOpenBracket();

  /// Inserts the exact [value], with an implied `×` next to an operand.
  ExpressionBuffer insertValue(CalcValue value) {
    final nextStartsOperand =
        _isNumberSymbolAt(cursor) ||
        _symbolAt(cursor) == CalculatorSymbols.openBracket ||
        _isValueAt(cursor);
    return _replaceBefore(0, [
      if (_endsWithOperand) const SymbolUnit(CalculatorSymbols.times),
      ValueUnit(value),
      if (nextStartsOperand) const SymbolUnit(CalculatorSymbols.times),
    ], cursorBack: nextStartsOperand ? 1 : 0);
  }

  /// Removes the unit before the cursor.
  ExpressionBuffer backspace() =>
      cursor == 0 ? this : _replaceBefore(1, const []);

  static const SymbolUnit _point = SymbolUnit(CalculatorSymbols.decimalPoint);

  ExpressionBuffer _insert(List<ExpressionUnit> inserted) =>
      _replaceBefore(0, inserted);

  /// Inserts digits or a point, with a `×` before them after `)`, `%` or a
  /// value, and after them before a value. The cursor stays in the number.
  ExpressionBuffer _insertNumberPart(List<ExpressionUnit> part) {
    final valueNext = _isValueAt(cursor);
    return _replaceBefore(0, [
      if (_endsWithNonNumberOperand) const SymbolUnit(CalculatorSymbols.times),
      ...part,
      if (valueNext) const SymbolUnit(CalculatorSymbols.times),
    ], cursorBack: valueNext ? 1 : 0);
  }

  /// Replaces the [count] units before the cursor with [replacement], and
  /// puts the cursor after it, less [cursorBack] units. Refused when the
  /// buffer would be too long.
  ExpressionBuffer _replaceBefore(
    int count,
    List<ExpressionUnit> replacement, {
    int cursorBack = 0,
  }) {
    final length = units.length - count + replacement.length;
    if (replacement.isNotEmpty && length > maxUnits) return this;
    final start = cursor - count;
    return ExpressionBuffer._(
      List.unmodifiable([
        ...units.take(start),
        ...replacement,
        ...units.skip(cursor),
      ]),
      start + replacement.length - cursorBack,
    );
  }

  /// Whether `)` fits at the cursor: a bracket before it is open, one is
  /// still open overall, and an operand comes before it.
  bool get _canCloseBracket =>
      _depthBefore(cursor) > 0 && openBrackets > 0 && _endsWithOperand;

  bool _isValueAt(int index) =>
      index >= 0 && index < units.length && units[index] is ValueUnit;

  bool _isDigitUnitAt(int index) =>
      index >= 0 && index < units.length && _isDigitUnit(units[index]);

  bool _isNumberSymbolAt(int index) =>
      index >= 0 && index < units.length && _isNumberSymbol(units[index]);

  String? _symbolAt(int index) {
    if (index < 0 || index >= units.length) return null;
    return switch (units[index]) {
      SymbolUnit(:final symbol) => symbol,
      ValueUnit() => null,
    };
  }

  /// Whether the `−` at [index] is a sign rather than a subtraction.
  bool _isUnaryMinusAt(int index) {
    if (index == 0) return true;
    if (units[index - 1] is ValueUnit) return false;
    final before = _symbolAt(index - 1)!;
    return CalculatorSymbols.operators.contains(before) ||
        before == CalculatorSymbols.openBracket;
  }

  /// Whether the unit before the cursor ends an operand.
  bool get _endsWithOperand {
    if (cursor == 0) return false;
    final unit = units[cursor - 1];
    if (unit is ValueUnit) return true;
    final symbol = (unit as SymbolUnit).symbol;
    return CalculatorSymbols.isDigit(symbol) ||
        symbol == CalculatorSymbols.decimalPoint ||
        symbol == CalculatorSymbols.closeBracket ||
        symbol == CalculatorSymbols.percent;
  }

  /// Whether the unit before the cursor ends an operand that is not a typed
  /// number: `)`, `%` or a value.
  bool get _endsWithNonNumberOperand =>
      _endsWithOperand && !_isNumberSymbol(units[cursor - 1]);

  /// The digits and point of the number just before the cursor.
  List<ExpressionUnit> get _numberBeforeCursor {
    var start = cursor;
    while (start > 0 && _isNumberSymbol(units[start - 1])) {
      start--;
    }
    return units.sublist(start, cursor);
  }

  /// The digits and point of the number the cursor is in or next to.
  List<ExpressionUnit> get _numberAroundCursor {
    var end = cursor;
    while (end < units.length && _isNumberSymbol(units[end])) {
      end++;
    }
    return [..._numberBeforeCursor, ...units.sublist(cursor, end)];
  }

  int _depthBefore(int index) {
    var depth = 0;
    for (final unit in units.take(index)) {
      if (unit == const SymbolUnit(CalculatorSymbols.openBracket)) depth++;
      if (unit == const SymbolUnit(CalculatorSymbols.closeBracket)) depth--;
    }
    return depth;
  }

  static bool _isDigitUnit(ExpressionUnit unit) =>
      unit is SymbolUnit && CalculatorSymbols.isDigit(unit.symbol);

  static bool _isNumberSymbol(ExpressionUnit unit) =>
      unit is SymbolUnit &&
      (CalculatorSymbols.isDigit(unit.symbol) ||
          unit.symbol == CalculatorSymbols.decimalPoint);

  /// A letter-only variable name for the [index]th value: a, b, … z, aa, ab…
  static String _variableName(int index) {
    final letters = StringBuffer();
    var n = index;
    do {
      letters.write(String.fromCharCode(0x61 + n % 26));
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return letters.toString().split('').reversed.join();
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressionBuffer &&
      other.cursor == cursor &&
      _listEquals(other.units, units);

  @override
  int get hashCode => Object.hash(cursor, Object.hashAll(units));

  @override
  String toString() {
    final text = units.map((unit) => '$unit').toList()..insert(cursor, '|');
    return 'ExpressionBuffer(${text.join()})';
  }

  static bool _listEquals(List<ExpressionUnit> a, List<ExpressionUnit> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
