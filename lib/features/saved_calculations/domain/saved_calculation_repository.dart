import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/features/saved_calculations/domain/saved_calculation.dart';

/// Stores saved calculations, most recently updated first.
abstract interface class SavedCalculationRepository {
  /// Every saved calculation, most recently updated first.
  Future<List<SavedCalculation>> list();

  /// Saves `expression` = `result` under `name`, timestamped now, and
  /// returns it with its assigned id.
  Future<SavedCalculation> add({
    required String name,
    required String expression,
    required CalcValue result,
  });

  /// Renames the entry with `id`, and updates when it was last touched.
  Future<void> rename(int id, String name);

  /// Removes the entry with `id`. Does nothing if it's already gone.
  Future<void> delete(int id);

  /// Removes every entry.
  Future<void> clear();
}
