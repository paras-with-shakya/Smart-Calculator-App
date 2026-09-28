import 'package:calc_engine/src/calc_result.dart';

/// Thrown inside the engine to stop evaluation with [error].
///
/// It never leaves the engine: `CalcEngine.evaluate` turns it into a
/// `CalcFailure`.
final class EvaluationException implements Exception {
  /// Creates an exception reporting [error].
  const EvaluationException(this.error);

  /// Why evaluation stopped.
  final CalcError error;

  @override
  String toString() => 'EvaluationException($error)';
}
