import 'package:calc_engine/src/number/calc_value.dart';

/// Why an expression has no result. The app turns each one into a
/// human-readable message; raw values such as NaN or Infinity never occur.
enum CalcError {
  /// There is nothing to calculate: the expression is empty or blank.
  empty,

  /// The expression is malformed, for example `5×÷3`, `()` or `1..2`.
  syntax,

  /// The expression stops where a number is still needed, for example `5+`
  /// or an unclosed bracket.
  incomplete,

  /// A division by zero, including `0÷0`.
  divisionByZero,

  /// A value reached 10^100 or more in size.
  overflow,

  /// Mathematically undefined for real numbers: a function argument outside
  /// its domain (`√−1`, `ln 0`, `asin 2`), `tan` at an odd multiple of 90°,
  /// a negative base raised to a power with no real root (`(−4)^(1/2)`),
  /// `0` raised to a negative power, or `!` of a negative or non-integer
  /// value.
  undefined,
}

/// The outcome of evaluating an expression: a [CalcSuccess] or a
/// [CalcFailure].
sealed class CalcResult {
  const CalcResult();
}

/// An expression's value.
final class CalcSuccess extends CalcResult {
  /// Creates a successful result holding [value].
  const CalcSuccess(this.value);

  /// The exact value.
  final CalcValue value;

  @override
  bool operator ==(Object other) =>
      other is CalcSuccess && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CalcSuccess($value)';
}

/// Why an expression could not be evaluated.
final class CalcFailure extends CalcResult {
  /// Creates a failed result with [error].
  const CalcFailure(this.error);

  /// What went wrong.
  final CalcError error;

  @override
  bool operator ==(Object other) =>
      other is CalcFailure && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'CalcFailure($error)';
}
