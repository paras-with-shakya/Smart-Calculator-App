import 'package:calc_engine/calc_engine.dart';

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
  equals,

  /// `^`, the power.
  power,

  /// `!`, the factorial.
  factorial,

  /// The constant π.
  pi,

  /// The constant e.
  euler,

  /// `sin(`
  sin(CalcFunction.sin),

  /// `cos(`
  cos(CalcFunction.cos),

  /// `tan(`
  tan(CalcFunction.tan),

  /// `asin(`
  asin(CalcFunction.asin),

  /// `acos(`
  acos(CalcFunction.acos),

  /// `atan(`
  atan(CalcFunction.atan),

  /// `sinh(`
  sinh(CalcFunction.sinh),

  /// `cosh(`
  cosh(CalcFunction.cosh),

  /// `tanh(`
  tanh(CalcFunction.tanh),

  /// `log(`, base 10.
  log(CalcFunction.log),

  /// `ln(`, natural.
  ln(CalcFunction.ln),

  /// `sqrt(`
  sqrt(CalcFunction.sqrt),

  /// `cbrt(`
  cbrt(CalcFunction.cbrt),

  /// `abs(`
  abs(CalcFunction.abs),

  /// `x²`: `^2`, applied to whatever operand precedes the cursor.
  square,

  /// `x³`: `^3`, applied to whatever operand precedes the cursor.
  cube,

  /// `10ˣ`: `10^`, ready for the exponent.
  powerOfTen,

  /// `eˣ`: `e^`, ready for the exponent.
  powerOfE;

  const CalculatorKey([this.function]);

  /// The function this key opens a call to, or null if it isn't a function
  /// key.
  final CalcFunction? function;

  /// The key for [digit] (0-9).
  static CalculatorKey digit(int digit) {
    RangeError.checkValueInInterval(digit, 0, 9, 'digit');
    return values[digit];
  }

  /// The digit this key types, or null if it isn't a digit key.
  int? get digitValue => index <= digit9.index ? index : null;
}
