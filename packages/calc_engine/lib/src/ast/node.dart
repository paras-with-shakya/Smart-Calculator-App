import 'package:calc_engine/src/number/calc_value.dart';

/// A node of a parsed expression.
sealed class Node {
  const Node();
}

/// A literal number.
final class NumberNode extends Node {
  /// Creates a literal holding [value].
  const NumberNode(this.value);

  /// The literal's value.
  final CalcValue value;
}

/// A named value supplied by the caller, such as a previous result.
final class VariableNode extends Node {
  /// Creates a reference to the variable [name].
  const VariableNode(this.name);

  /// The variable's name.
  final String name;
}

/// Unary minus.
final class NegateNode extends Node {
  /// Creates the negation of [operand].
  const NegateNode(this.operand);

  /// The negated expression.
  final Node operand;
}

/// Postfix percent: `operand%`.
final class PercentNode extends Node {
  /// Creates [operand] followed by `%`.
  const PercentNode(this.operand);

  /// The expression before `%`.
  final Node operand;
}

/// Postfix factorial: `operand!`.
final class FactorialNode extends Node {
  /// Creates [operand] followed by `!`.
  const FactorialNode(this.operand);

  /// The expression before `!`.
  final Node operand;
}

/// A built-in constant.
enum CalcConstant {
  /// π (pi).
  pi,

  /// Euler's number.
  e,
}

/// A reference to a [CalcConstant], such as `π` or `e`.
final class ConstantNode extends Node {
  /// Creates a reference to [constant].
  const ConstantNode(this.constant);

  /// Which constant.
  final CalcConstant constant;
}

/// A one-argument function, such as `sin(`.
enum CalcFunction {
  /// sin, cos, tan (in the evaluator's current angle mode)
  sin,
  cos,
  tan,

  /// asin, acos, atan (returning the evaluator's current angle mode)
  asin,
  acos,
  atan,

  /// sinh, cosh, tanh (never affected by angle mode)
  sinh,
  cosh,
  tanh,

  /// log base 10.
  log,

  /// Natural log.
  ln,

  /// Square root, exact for a perfect square.
  sqrt,

  /// Cube root, exact for a perfect cube. Defined for negative numbers too.
  cbrt,

  /// Absolute value.
  abs,
}

/// A function call: `name(argument)`.
final class FunctionCallNode extends Node {
  /// Creates a call to [function] with [argument].
  const FunctionCallNode(this.function, this.argument);

  /// Which function.
  final CalcFunction function;

  /// The argument expression.
  final Node argument;
}

/// The binary operators.
enum BinaryOperator {
  /// `+`
  add,

  /// `−`
  subtract,

  /// `×`, including implied multiplication such as `2(3)`.
  multiply,

  /// `÷`
  divide,

  /// `^`: `xʸ`, and `x²` (`^2`), `10ˣ` (`10^`) and `eˣ` (`e^`) built from it.
  /// Right-associative: `2^3^2` is `2^(3^2)`.
  power,
}

/// A binary operation.
final class BinaryNode extends Node {
  /// Creates [left] [operator] [right].
  const BinaryNode(this.operator, this.left, this.right);

  /// The operator.
  final BinaryOperator operator;

  /// The left operand.
  final Node left;

  /// The right operand.
  final Node right;
}
