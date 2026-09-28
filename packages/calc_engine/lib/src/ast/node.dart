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
