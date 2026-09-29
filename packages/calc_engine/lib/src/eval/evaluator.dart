import 'dart:math' as math;

import 'package:calc_engine/src/angle_mode.dart';
import 'package:calc_engine/src/ast/node.dart';
import 'package:calc_engine/src/calc_result.dart';
import 'package:calc_engine/src/evaluation_exception.dart';
import 'package:calc_engine/src/number/calc_value.dart';
import 'package:rational/rational.dart';

/// Evaluates [node], looking names up in [variables] and trigonometric
/// functions working in [angleMode].
///
/// Basic arithmetic (`+ − × ÷ %`), whole-number powers and factorial stay
/// exact; irrational results (most functions, non-perfect roots, fractional
/// powers) are approximate (DEC-008, and Phase 5's DEC-047).
///
/// Percent follows DEC-036 ("smart percent"): when the right operand of `+`
/// or `−` is a percentage, it is a percentage of the left operand
/// (`50+10%` = 55). Everywhere else `b%` is b/100 (`50×10%` = 5).
///
/// Throws an [EvaluationException] for an unknown name ([CalcError.syntax]),
/// a division by zero, a value out of a function's real domain
/// ([CalcError.undefined]), or a value of 10^100 or more
/// ([CalcError.overflow]).
CalcValue evaluate(
  Node node,
  Map<String, CalcValue> variables,
  AngleMode angleMode,
) => _Evaluator(variables, angleMode).value(node);

final CalcValue _hundred = CalcValue.fromInt(100);
final CalcValue _one = CalcValue.fromInt(1);

/// Exponents (or factorial inputs) beyond this are rejected as overflow
/// without computing: any base whose magnitude isn't 0, 1 or -1 has long
/// since overflowed 10^100 by then, and this keeps pathological input from
/// spending time on a huge exact computation.
const int _maxIntegerMagnitude = 2000;

class _Evaluator {
  const _Evaluator(this._variables, this._angleMode);

  final Map<String, CalcValue> _variables;
  final AngleMode _angleMode;

  CalcValue value(Node node) => _checked(switch (node) {
    NumberNode(:final value) => value,
    VariableNode(:final name) =>
      _variables[name] ?? (throw const EvaluationException(CalcError.syntax)),
    ConstantNode(:final constant) => _constant(constant),
    NegateNode(:final operand) => -value(operand),
    PercentNode(:final operand) => value(operand) / _hundred,
    FactorialNode(:final operand) => _factorial(value(operand)),
    FunctionCallNode(:final function, :final argument) => _call(
      function,
      value(argument),
    ),
    BinaryNode(:final operator, :final left, :final right) => _binary(
      operator,
      left,
      right,
    ),
  });

  CalcValue _binary(BinaryOperator operator, Node leftNode, Node rightNode) {
    final left = value(leftNode);
    switch (operator) {
      case BinaryOperator.add || BinaryOperator.subtract:
        final percentage = _percentage(rightNode);
        final right = percentage == null
            ? value(rightNode)
            : _checked(left * percentage / _hundred);
        return operator == BinaryOperator.add ? left + right : left - right;
      case BinaryOperator.multiply:
        return left * value(rightNode);
      case BinaryOperator.divide:
        final right = value(rightNode);
        if (right.isZero) {
          throw const EvaluationException(CalcError.divisionByZero);
        }
        return left / right;
      case BinaryOperator.power:
        return _power(left, value(rightNode));
    }
  }

  /// The percentage [node] stands for when it is `p%`, possibly behind
  /// unary signs (`−10%`): the signed p. Null when [node] is not a
  /// percentage.
  CalcValue? _percentage(Node node) => switch (node) {
    PercentNode(:final operand) => value(operand),
    NegateNode(:final operand) => switch (_percentage(operand)) {
      final CalcValue inner => -inner,
      null => null,
    },
    _ => null,
  };

  CalcValue _constant(CalcConstant constant) =>
      CalcValue.approximate(switch (constant) {
        CalcConstant.pi => math.pi,
        CalcConstant.e => math.e,
      });

  /// `n!`: `n` must be an exact, non-negative whole number.
  CalcValue _factorial(CalcValue operand) {
    final exact = operand.exactValue;
    if (exact == null || !exact.isInteger || exact.signum < 0) {
      throw const EvaluationException(CalcError.undefined);
    }
    final n = exact.toBigInt();
    if (n > BigInt.from(_maxIntegerMagnitude)) {
      throw const EvaluationException(CalcError.overflow);
    }
    var result = BigInt.one;
    for (var i = BigInt.two; i <= n; i += BigInt.one) {
      result *= i;
    }
    return calcValueFromRational(Rational(result));
  }

  CalcValue _call(CalcFunction function, CalcValue argument) =>
      switch (function) {
        CalcFunction.sin => _trig(math.sin, argument),
        CalcFunction.cos => _trig(math.cos, argument),
        CalcFunction.tan => _tan(argument),
        CalcFunction.asin => _inverseTrig(math.asin, argument, domain: (-1, 1)),
        CalcFunction.acos => _inverseTrig(math.acos, argument, domain: (-1, 1)),
        CalcFunction.atan => _inverseTrig(math.atan, argument, domain: null),
        CalcFunction.sinh => CalcValue.approximate(_sinh(argument.toDouble())),
        CalcFunction.cosh => CalcValue.approximate(_cosh(argument.toDouble())),
        CalcFunction.tanh => CalcValue.approximate(
          _sinh(argument.toDouble()) / _cosh(argument.toDouble()),
        ),
        CalcFunction.log => _logarithm(argument, math.ln10),
        CalcFunction.ln => _logarithm(argument, 1),
        CalcFunction.sqrt => _root(argument, 2),
        CalcFunction.cbrt => _root(argument, 3, allowNegative: true),
        CalcFunction.abs => argument.abs(),
      };

  /// `sin`/`cos`: converting through degrees introduces floating-point
  /// noise right where the mathematical answer is exactly zero (`cos(90)`
  /// computes to about `6e-17`, not `0`). Snapping a near-zero result to
  /// exact zero matches every other calculator's behaviour at these axis
  /// angles, and 12-significant-digit rounding already absorbs the (much
  /// smaller, relative) noise everywhere else (`sin(30)` = `0.5`).
  CalcValue _trig(double Function(double) fn, CalcValue argument) =>
      CalcValue.approximate(_snapToZero(fn(_toRadians(argument.toDouble()))));

  /// `tan`, with the one case a `double` conversion can't catch on its own:
  /// an exact input of an odd multiple of 90° in degree mode has no
  /// tangent, but converting it to radians first and calling `tan` would
  /// silently return a huge (but finite) number instead of erroring.
  CalcValue _tan(CalcValue argument) {
    final exact = argument.exactValue;
    if (_angleMode == AngleMode.degrees && exact != null && exact.isInteger) {
      final mod180 = exact.toBigInt() % BigInt.from(180);
      if (mod180 == BigInt.from(90) || mod180 == BigInt.from(-90)) {
        throw const EvaluationException(CalcError.undefined);
      }
    }
    return CalcValue.approximate(
      _snapToZero(math.tan(_toRadians(argument.toDouble()))),
    );
  }

  static const double _zeroEpsilon = 1e-10;

  static double _snapToZero(double value) =>
      value.abs() < _zeroEpsilon ? 0.0 : value;

  CalcValue _inverseTrig(
    double Function(double) fn,
    CalcValue argument, {
    required (num, num)? domain,
  }) {
    final x = argument.toDouble();
    if (domain != null && (x < domain.$1 || x > domain.$2)) {
      throw const EvaluationException(CalcError.undefined);
    }
    return CalcValue.approximate(_fromRadians(fn(x)));
  }

  double _toRadians(double value) =>
      _angleMode == AngleMode.degrees ? value * math.pi / 180 : value;

  double _fromRadians(double radians) =>
      _angleMode == AngleMode.degrees ? radians * 180 / math.pi : radians;

  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
  static double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;

  CalcValue _logarithm(CalcValue argument, double divisor) {
    final x = argument.toDouble();
    if (x <= 0) throw const EvaluationException(CalcError.undefined);
    return CalcValue.approximate(math.log(x) / divisor);
  }

  /// The [degree]th real root of [argument] (2 for √, 3 for ∛). Exact for a
  /// perfect [degree]th power; negative inputs are only allowed (and only
  /// possible) when [allowNegative] (cube root and beyond of an odd
  /// degree).
  CalcValue _root(
    CalcValue argument,
    int degree, {
    bool allowNegative = false,
  }) {
    if (!allowNegative && argument.isNegative) {
      throw const EvaluationException(CalcError.undefined);
    }
    final exact = argument.exactValue;
    if (exact != null) {
      final negative = exact.signum < 0;
      final numeratorRoot = _exactRoot(exact.numerator.abs(), degree);
      final denominatorRoot = _exactRoot(exact.denominator, degree);
      if (numeratorRoot != null && denominatorRoot != null) {
        final magnitude = Rational(numeratorRoot, denominatorRoot);
        return calcValueFromRational(negative ? -magnitude : magnitude);
      }
    }
    final x = argument.toDouble();
    final magnitude = math.pow(x.abs(), 1 / degree).toDouble();
    return CalcValue.approximate(x < 0 ? -magnitude : magnitude);
  }

  /// The exact [degree]th root of the non-negative [n], or null if it isn't
  /// a perfect [degree]th power.
  static BigInt? _exactRoot(BigInt n, int degree) {
    if (n == BigInt.zero) return BigInt.zero;
    var low = BigInt.zero;
    var high = BigInt.one;
    while (high.pow(degree) <= n) {
      high *= BigInt.two;
    }
    while (high - low > BigInt.one) {
      final mid = (low + high) ~/ BigInt.two;
      if (mid.pow(degree) <= n) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low.pow(degree) == n ? low : null;
  }

  /// `base^exponent`. Whole-number exponents of an exact base stay exact
  /// (including `0^0` = 1). A negative base needs a rational exponent with
  /// an odd denominator to have a real result: `base^(p/q)` is
  /// `(base^(1/q))^p`, and an odd-index real root of a negative number is
  /// itself negative, so `(−8)^(1/3)` = −2, and `(−8)^(2/3)` = 4 (the
  /// square of that). The same odd-root identity is exact for a positive
  /// base too, so `4^(1/2)` = 2, not an approximate `1.9999999999999998`.
  CalcValue _power(CalcValue base, CalcValue exponent) {
    final exactExponent = exponent.exactValue;
    if (exactExponent != null && exactExponent.isInteger) {
      return _integerPower(base, exactExponent.toBigInt());
    }

    final baseIsNegative = base.isNegative;
    if (baseIsNegative && exactExponent == null) {
      // An irrational exponent leaves no odd/even denominator to check.
      throw const EvaluationException(CalcError.undefined);
    }
    if (baseIsNegative && exactExponent!.denominator.isEven) {
      throw const EvaluationException(CalcError.undefined);
    }
    if (base.isZero &&
        (exactExponent == null
            ? exponent.isNegative
            : exactExponent.signum < 0)) {
      throw const EvaluationException(CalcError.undefined);
    }

    final exact = _exactPower(base.exactValue, exactExponent, baseIsNegative);
    if (exact != null) return calcValueFromRational(exact);

    final baseValue = base.toDouble();
    if (baseIsNegative) {
      final p = exactExponent!.numerator;
      final magnitude = math.pow(
        -baseValue,
        p.toDouble() / exactExponent.denominator.toDouble(),
      );
      return CalcValue.approximate(
        (p.isOdd ? -magnitude : magnitude).toDouble(),
      );
    }
    return CalcValue.approximate(
      math.pow(baseValue, exponent.toDouble()).toDouble(),
    );
  }

  /// `base^(p/q)` when it has an exact value: `base` and the exponent (in
  /// lowest terms) are both exact, `|base|` has an exact `q`th root, and
  /// `q` isn't so large that finding one isn't worth attempting. Null
  /// otherwise (the caller falls back to an approximate `double`).
  Rational? _exactPower(
    Rational? base,
    Rational? exponent,
    bool baseIsNegative,
  ) {
    if (base == null || exponent == null) return null;
    final q = exponent.denominator;
    if (q > BigInt.from(_maxIntegerMagnitude)) return null;
    final p = exponent.numerator;
    if (p.abs() > BigInt.from(_maxIntegerMagnitude)) return null;
    final absBase = base.abs();
    final numeratorRoot = _exactRoot(absBase.numerator, q.toInt());
    final denominatorRoot = _exactRoot(absBase.denominator, q.toInt());
    if (numeratorRoot == null || denominatorRoot == null) return null;
    final root = Rational(numeratorRoot, denominatorRoot).pow(p.toInt());
    return baseIsNegative && p.isOdd ? -root : root;
  }

  CalcValue _integerPower(CalcValue base, BigInt exponent) {
    if (base.isZero) {
      if (exponent.isNegative) {
        throw const EvaluationException(CalcError.undefined);
      }
      return exponent == BigInt.zero ? _one : CalcValue.zero;
    }
    if (exponent.abs() > BigInt.from(_maxIntegerMagnitude)) {
      throw const EvaluationException(CalcError.overflow);
    }
    final exactBase = base.exactValue;
    if (exactBase != null) {
      return calcValueFromRational(exactBase.pow(exponent.toInt()));
    }
    return CalcValue.approximate(
      math.pow(base.toDouble(), exponent.toInt()).toDouble(),
    );
  }

  static CalcValue _checked(CalcValue result) {
    if (result.isTooLarge) throw const EvaluationException(CalcError.overflow);
    return result;
  }
}
