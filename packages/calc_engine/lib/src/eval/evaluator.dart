import 'package:calc_engine/src/ast/node.dart';
import 'package:calc_engine/src/calc_result.dart';
import 'package:calc_engine/src/evaluation_exception.dart';
import 'package:calc_engine/src/number/calc_value.dart';

/// Evaluates [node] exactly, looking names up in [variables].
///
/// Percent follows DEC-036 ("smart percent"): when the right operand of `+`
/// or `−` is a percentage, it is a percentage of the left operand
/// (`50+10%` = 55). Everywhere else `b%` is b/100 (`50×10%` = 5).
///
/// Throws an [EvaluationException] for an unknown name
/// ([CalcError.syntax]), a division by zero, or a value of 10^100 or more
/// ([CalcError.overflow]).
CalcValue evaluate(Node node, Map<String, CalcValue> variables) =>
    _Evaluator(variables).value(node);

final CalcValue _hundred = CalcValue.fromInt(100);

class _Evaluator {
  const _Evaluator(this._variables);

  final Map<String, CalcValue> _variables;

  CalcValue value(Node node) => _checked(switch (node) {
    NumberNode(:final value) => value,
    VariableNode(:final name) =>
      _variables[name] ?? (throw const EvaluationException(CalcError.syntax)),
    NegateNode(:final operand) => -value(operand),
    PercentNode(:final operand) => value(operand) / _hundred,
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

  static CalcValue _checked(CalcValue result) {
    if (result.isTooLarge) throw const EvaluationException(CalcError.overflow);
    return result;
  }
}
