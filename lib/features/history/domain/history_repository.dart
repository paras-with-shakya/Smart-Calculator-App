import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/features/history/domain/history_entry.dart';

/// Stores calculation history, newest first.
abstract interface class HistoryRepository {
  /// Every entry, newest first.
  Future<List<HistoryEntry>> list();

  /// Adds an entry for [expression] = [result] in [mode], timestamped now,
  /// and returns it with its assigned id.
  Future<HistoryEntry> add({
    required String expression,
    required CalcValue result,
    required CalculatorMode mode,
  });

  /// Removes the entry with [id]. Does nothing if it's already gone.
  Future<void> delete(int id);

  /// Removes every entry.
  Future<void> clear();

  /// Keeps only the [keep] newest entries (newest by the same order as
  /// [list]) and removes the rest. [keep] must be at least 1.
  Future<void> trimTo(int keep);
}
