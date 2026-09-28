/// The inputs of the calculator: the keypad's keys, plus explicit brackets
/// for a hardware keyboard.
enum CalculatorKey {
  /// 0
  digit0,

  /// 1
  digit1,

  /// 2
  digit2,

  /// 3
  digit3,

  /// 4
  digit4,

  /// 5
  digit5,

  /// 6
  digit6,

  /// 7
  digit7,

  /// 8
  digit8,

  /// 9
  digit9,

  /// The decimal point.
  decimalPoint,

  /// +
  add,

  /// −
  subtract,

  /// ×
  multiply,

  /// ÷
  divide,

  /// %
  percent,

  /// The single bracket key: opens or closes, depending on context.
  brackets,

  /// `(`, from a keyboard.
  openBracket,

  /// `)`, from a keyboard.
  closeBracket,

  /// Clears everything except the memory.
  allClear,

  /// Deletes the unit before the cursor.
  backspace,

  /// Evaluates the expression.
  equals;

  /// The key for [digit] (0-9).
  static CalculatorKey digit(int digit) {
    RangeError.checkValueInInterval(digit, 0, 9, 'digit');
    return values[digit];
  }

  /// The digit this key types, or null if it isn't a digit key.
  int? get digitValue => index <= digit9.index ? index : null;
}
