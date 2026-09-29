import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/features/saved_calculations/data/sqflite_saved_calculation_repository.dart';
import 'package:smart_calculator/features/saved_calculations/domain/saved_calculation.dart';

/// The saved calculations, most recently updated first.
final AsyncNotifierProvider<SavedCalculationsNotifier, List<SavedCalculation>>
savedCalculationsProvider =
    AsyncNotifierProvider<SavedCalculationsNotifier, List<SavedCalculation>>(
      SavedCalculationsNotifier.new,
    );

/// Loads and updates the saved calculations.
class SavedCalculationsNotifier extends AsyncNotifier<List<SavedCalculation>> {
  @override
  Future<List<SavedCalculation>> build() =>
      ref.watch(savedCalculationRepositoryProvider).list();

  /// Saves `expression` = `result` under `name`.
  Future<void> add({
    required String name,
    required String expression,
    required CalcValue result,
  }) async {
    final saved = await ref
        .read(savedCalculationRepositoryProvider)
        .add(name: name, expression: expression, result: result);
    if (!ref.mounted) return;
    final current = state.value ?? const [];
    state = AsyncData([saved, ...current]);
  }

  /// Renames the entry with `id`. Reloads the list, since renaming also
  /// moves it to the top (most recently updated first).
  Future<void> rename(int id, String name) async {
    await ref.read(savedCalculationRepositoryProvider).rename(id, name);
    if (!ref.mounted) return;
    state = AsyncData(
      await ref.read(savedCalculationRepositoryProvider).list(),
    );
  }

  /// Removes the entry with `id`.
  Future<void> delete(int id) async {
    await ref.read(savedCalculationRepositoryProvider).delete(id);
    if (!ref.mounted) return;
    final current = state.value ?? const [];
    state = AsyncData([
      for (final entry in current)
        if (entry.id != id) entry,
    ]);
  }

  /// Removes every entry.
  Future<void> clear() async {
    await ref.read(savedCalculationRepositoryProvider).clear();
    if (!ref.mounted) return;
    state = const AsyncData([]);
  }
}
