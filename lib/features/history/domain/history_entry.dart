import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';

/// One calculation the user ran with `=`.
///
/// [expression] is locale-neutral text, kept only to show what was typed;
/// it is never re-parsed. Reusing an entry acts on the exact [result], the
/// same way continuing after `=` and recalling the memory do (DEC-040).
final class HistoryEntry {
  /// Creates a history entry.
  const HistoryEntry({
    required this.id,
    required this.expression,
    required this.result,
    required this.mode,
    required this.createdAt,
  });

  /// The row id, unique within the history.
  final int id;

  /// What was typed, as locale-neutral display text.
  final String expression;

  /// The exact answer.
  final CalcValue result;

  /// The mode `=` was pressed in.
  final CalculatorMode mode;

  /// When `=` produced [result], in UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is HistoryEntry &&
      other.id == id &&
      other.expression == expression &&
      other.result == result &&
      other.mode == mode &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, expression, result, mode, createdAt);

  @override
  String toString() =>
      'HistoryEntry(#$id, $expression = $result, ${mode.storageId}, $createdAt)';
}
