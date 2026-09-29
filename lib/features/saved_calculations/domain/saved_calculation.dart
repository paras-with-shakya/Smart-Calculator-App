import 'package:calc_engine/calc_engine.dart';

/// A calculation the user chose to keep, under a name they gave it.
///
/// Only the basic calculator can produce one right now (`kind` is always
/// `'basic'`): the expression and result are exactly what a history entry
/// holds. Future calculator modes (Phase 7's EMI, GST and so on) will need
/// their own `kind` and their own shape for what's saved; this type will
/// grow to match when that happens.
final class SavedCalculation {
  /// Creates a saved calculation.
  const SavedCalculation({
    required this.id,
    required this.name,
    required this.expression,
    required this.result,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The row id, unique within the saved calculations.
  final int id;

  /// The name the user gave it.
  final String name;

  /// What was typed, as locale-neutral display text (never re-parsed; see
  /// `HistoryEntry`).
  final String expression;

  /// The exact result.
  final CalcValue result;

  /// When it was first saved, in UTC.
  final DateTime createdAt;

  /// When it was last renamed (or first saved, if never renamed), in UTC.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is SavedCalculation &&
      other.id == id &&
      other.name == name &&
      other.expression == expression &&
      other.result == result &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, expression, result, createdAt, updatedAt);

  @override
  String toString() => 'SavedCalculation(#$id, $name: $expression = $result)';
}
