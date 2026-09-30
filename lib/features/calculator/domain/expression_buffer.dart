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

  /// Power, `xʸ`.
  static const String power = '^';

  /// Postfix factorial.
  static const String factorial = '!';

  /// The constant π.
  static const String pi = 'π';

  /// The constant e (Euler's number).
  static const String euler = 'e';

  /// Closing bracket.
  static const String closeBracket = ')';

  /// Decimal point, whatever the region shows (the display localizes it).
  static const String decimalPoint = '.';

  /// The binary operators.
  static const Set<String> operators = {plus, minus, times, divide, power};

  /// The constants, which stand for a number.
  static const Set<String> constants = {pi, euler};

  /// The symbol that opens a call to [function]: `sin(`, `sqrt(`. It is one
  /// unit, so backspace removes the name and its bracket together.
  static String functionOpener(CalcFunction function) => '${function.name}(';

  /// Whether [symbol] opens a function call, such as `sin(`.
  static bool isFunctionOpener(String symbol) =>
      symbol.length > 1 && symbol.endsWith('(');

  /// Whether [symbol] opens a bracket: `(` or a function call.
  static bool opensBracket(String symbol) =>
      symbol == openBracket || isFunctionOpener(symbol);

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

/// A typed symbol: a digit, the decimal point, an operator, `%`, `!`, a
/// constant, a bracket or a function opener such as `sin(`.
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
///   operands never look like one number;
/// - a constant, function or value next to an operand gets an explicit `×`,
///   so `2π` reads as `2×π` and `π2` cannot be misread;
/// - `!` and `%` only after an operand, and `−` after `^` is a sign
///   (`2^−3`);
/// - backspacing a constant, function or value also removes a `×` it left
///   with no operand before it, so deleting one never strands an operator
///   the user didn't type (`backspace()`);
/// - `x²`/`x³`/`10ˣ`/`eˣ` (`insertPowerOf`, `insertPowerOfTen`,
///   `insertPowerOfE`) are each `^` plus an operand in one step, refused
///   wherever inserting either half alone wouldn't make sense.
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
        previous != null && CalculatorSymbols.opensBracket(previous)) {
      return isMinus
          ? _insert([const SymbolUnit(CalculatorSymbols.minus)])
          : this;
    }
    if (previous != null && CalculatorSymbols.operators.contains(previous)) {
      final multiplicative = _isMultiplicative(previous);
      if (isMinus && multiplicative) {
        return _insert([const SymbolUnit(CalculatorSymbols.minus)]);
      }
      if (previous == CalculatorSymbols.minus && _isUnaryMinusAt(cursor - 1)) {
        final beforeMinus = _symbolAt(cursor - 2);
        final afterMultiplicative =
            beforeMinus != null && _isMultiplicative(beforeMinus);
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

  /// Types `!`, which must follow a number, `)`, `%`, a constant or a value.
  ExpressionBuffer insertFactorial() {
    if (!_endsWithOperand ||
        _symbolAt(cursor - 1) == CalculatorSymbols.factorial) {
      return this;
    }
    return _insert([const SymbolUnit(CalculatorSymbols.factorial)]);
  }

  /// Types the constant [symbol] (π or e), with a `×` before it after an
  /// operand and after it before one.
  ExpressionBuffer insertConstant(String symbol) {
    assert(
      CalculatorSymbols.constants.contains(symbol),
      'Not a constant: $symbol',
    );
    return _insertOperand(SymbolUnit(symbol));
  }

  /// Types the opener of a call to [function], such as `sin(`, with a `×`
  /// before it after an operand. The call is closed by `)`, or when the
  /// expression is evaluated.
  ExpressionBuffer insertFunction(CalcFunction function) {
    final opener = SymbolUnit(CalculatorSymbols.functionOpener(function));
    return _endsWithOperand
        ? _insert([const SymbolUnit(CalculatorSymbols.times), opener])
        : _insert([opener]);
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
  ExpressionBuffer insertValue(CalcValue value) =>
      _insertOperand(ValueUnit(value));

  /// Types `^` followed by [digit] (x² is `insertPowerOf('2')`, x³ is
  /// `insertPowerOf('3')`), only when an operand precedes the cursor.
  /// Without that guard, `^` alone silently does nothing wherever it isn't
  /// allowed (an empty buffer, right after `(`, right after a function
  /// opener), and [digit] would then be inserted on its own instead of
  /// being silently dropped along with it — this refuses the whole thing
  /// in that case, the same way [insertFactorial] does.
  ExpressionBuffer insertPowerOf(String digit) {
    assert(CalculatorSymbols.isDigit(digit), 'Not a digit: $digit');
    if (!_endsWithOperand) return this;
    return insertOperator(CalculatorSymbols.power).insertDigit(digit);
  }

  /// Types `10^`, ready for the exponent (`10ˣ`).
  ExpressionBuffer insertPowerOfTen() =>
      _insertOperandThenPower(ValueUnit(CalcValue.fromInt(10)));

  /// Types `e^`, ready for the exponent (`eˣ`).
  ExpressionBuffer insertPowerOfE() =>
      _insertOperandThenPower(const SymbolUnit(CalculatorSymbols.euler));

  /// Inserts [operand] then `^` as one step, with a `×` before [operand]
  /// after an existing operand. Refused, like every operand insert, when an
  /// operand already starts right after the cursor: unlike a plain value or
  /// constant, `^` must bind to the exponent typed next, so there is no
  /// sensible place to put an implied `×` between it and existing content.
  ExpressionBuffer _insertOperandThenPower(ExpressionUnit operand) {
    if (_startsOperandAt(cursor)) return this;
    return _replaceBefore(0, [
      if (_endsWithOperand) const SymbolUnit(CalculatorSymbols.times),
      operand,
      const SymbolUnit(CalculatorSymbols.power),
    ]);
  }

  /// Removes the unit before the cursor. If that exposes a `×` the buffer
  /// itself inserted with no operand before it — deleting a constant,
  /// function or value can leave one, since the operand it multiplied is
  /// gone but the operator it stood next to on the *other* side wasn't
  /// typed by the user (`sin(`, cursor before it, then π then backspace
  /// would otherwise leave `×sin(`) — that `×` is removed too, in the same
  /// step. A `×` with a real operand before it (`5×`, mid-typing) is left
  /// alone; it isn't orphaned, just unfinished.
  ExpressionBuffer backspace() =>
      cursor == 0 ? this : _replaceBefore(1, const [])._withoutOrphanedTimes();

  /// Removes the `×` at the cursor if nothing before it ends an operand.
  ExpressionBuffer _withoutOrphanedTimes() {
    if (cursor >= units.length ||
        _symbolAt(cursor) != CalculatorSymbols.times ||
        _unitEndsOperand(cursor > 0 ? units[cursor - 1] : null)) {
      return this;
    }
    return ExpressionBuffer._(
      List.unmodifiable([...units.take(cursor), ...units.skip(cursor + 1)]),
      cursor,
    )._withoutOrphanedTimes();
  }

  static const SymbolUnit _point = SymbolUnit(CalculatorSymbols.decimalPoint);

  ExpressionBuffer _insert(List<ExpressionUnit> inserted) =>
      _replaceBefore(0, inserted);

  /// Inserts a whole operand (a value or a constant), with a `×` before it
  /// after an operand and after it before one.
  ExpressionBuffer _insertOperand(ExpressionUnit operand) {
    final nextStartsOperand = _startsOperandAt(cursor);
    return _replaceBefore(0, [
      if (_endsWithOperand) const SymbolUnit(CalculatorSymbols.times),
      operand,
      if (nextStartsOperand) const SymbolUnit(CalculatorSymbols.times),
    ], cursorBack: nextStartsOperand ? 1 : 0);
  }

  /// Inserts digits or a point, with a `×` before them after `)`, `%` or a
  /// value, and after them before a value. The cursor stays in the number.
  ExpressionBuffer _insertNumberPart(List<ExpressionUnit> part) {
    final valueNext = _isWholeOperandAt(cursor);
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

  /// Whether the unit at [index] is a value, a constant or a function
  /// opener: an operand a typed number must not run into.
  bool _isWholeOperandAt(int index) {
    if (_isValueAt(index)) return true;
    final symbol = _symbolAt(index);
    return symbol != null &&
        (CalculatorSymbols.constants.contains(symbol) ||
            CalculatorSymbols.isFunctionOpener(symbol));
  }

  /// Whether an operand starts at [index].
  bool _startsOperandAt(int index) =>
      _isNumberSymbolAt(index) ||
      _isWholeOperandAt(index) ||
      _symbolAt(index) == CalculatorSymbols.openBracket;

  /// Whether [symbol] is an operator after which `−` is a sign.
  static bool _isMultiplicative(String symbol) =>
      symbol == CalculatorSymbols.times ||
      symbol == CalculatorSymbols.divide ||
      symbol == CalculatorSymbols.power;

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
        CalculatorSymbols.opensBracket(before);
  }

  /// Whether the unit before the cursor ends an operand.
  bool get _endsWithOperand =>
      cursor > 0 && _unitEndsOperand(units[cursor - 1]);

  /// Whether [unit] ends an operand: a digit, the decimal point, `)`, `%`,
  /// `!`, a constant or a value. Nothing there (`null`) does not.
  static bool _unitEndsOperand(ExpressionUnit? unit) {
    if (unit == null) return false;
    if (unit is ValueUnit) return true;
    final symbol = (unit as SymbolUnit).symbol;
    return CalculatorSymbols.isDigit(symbol) ||
        symbol == CalculatorSymbols.decimalPoint ||
        symbol == CalculatorSymbols.closeBracket ||
        symbol == CalculatorSymbols.percent ||
        symbol == CalculatorSymbols.factorial ||
        CalculatorSymbols.constants.contains(symbol);
  }

  /// Whether the unit before the cursor ends an operand that is not a typed
  /// number: `)`, `%`, `!`, a constant or a value.
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
      if (unit is! SymbolUnit) continue;
      if (CalculatorSymbols.opensBracket(unit.symbol)) depth++;
      if (unit.symbol == CalculatorSymbols.closeBracket) depth--;
    }
    return depth;
  }

  static bool _isDigitUnit(ExpressionUnit unit) =>
      unit is SymbolUnit && CalculatorSymbols.isDigit(unit.symbol);

  static bool _isNumberSymbol(ExpressionUnit unit) =>
      unit is SymbolUnit &&
      (CalculatorSymbols.isDigit(unit.symbol) ||
          unit.symbol == CalculatorSymbols.decimalPoint);

  /// A letter-only variable name for the [index]th value: a, b, c, d, f, g,
  /// … z, aa, ab… The single letter `e` is skipped: the engine always reads
  /// it as Euler's number, never a variable (see CalcEngine, "'e' and 'π'
  /// are always the constants"), so a value named `e` would silently be
  /// replaced by 2.718… instead of the value actually inserted.
  static String _variableName(int index) {
    final letters = StringBuffer();
    var n = index < 4 ? index : index + 1;
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
