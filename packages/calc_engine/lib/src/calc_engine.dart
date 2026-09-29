import 'package:calc_engine/src/angle_mode.dart';
import 'package:calc_engine/src/calc_result.dart';
import 'package:calc_engine/src/eval/evaluator.dart' as evaluator;
import 'package:calc_engine/src/evaluation_exception.dart';
import 'package:calc_engine/src/lexer/lexer.dart';
import 'package:calc_engine/src/number/calc_value.dart';
import 'package:calc_engine/src/parser/parser.dart';

/// The most tokens [CalcEngine.evaluate] accepts; longer input is a syntax
/// error. This keeps evaluation fast and its recursion shallow. The app's
/// input limit is far below it.
const int maxTokens = 1000;

/// Evaluates calculator expressions exactly.
///
/// Expressions use decimal numbers, `+ − × ÷` (or `+ - * /`), postfix `%`,
/// brackets, unary signs and letter-only variable names. The result is
/// always a [CalcResult]; evaluation never throws.
final class CalcEngine {
  /// Creates an engine.
  const CalcEngine();

  /// Evaluates [expression], looking names up in [variables]. Trigonometric
  /// functions (not the hyperbolic ones) work in [angleMode].
  ///
  /// Variables let a caller reuse exact values, such as a previous result
  /// or the memory, without rounding them through text.
  CalcResult evaluate(
    String expression, {
    Map<String, CalcValue> variables = const {},
    AngleMode angleMode = AngleMode.degrees,
  }) {
    try {
      final tokens = tokenize(expression);
      if (tokens.isEmpty) return const CalcFailure(CalcError.empty);
      if (tokens.length > maxTokens) {
        return const CalcFailure(CalcError.syntax);
      }
      return CalcSuccess(
        evaluator.evaluate(parse(tokens), variables, angleMode),
      );
    } on EvaluationException catch (exception) {
      return CalcFailure(exception.error);
    }
  }
}
