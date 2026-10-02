import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/features/history/data/sqflite_history_repository.dart';
import 'package:smart_calculator/features/history/domain/history_entry.dart';

/// The calculation history, newest first.
final AsyncNotifierProvider<HistoryNotifier, List<HistoryEntry>>
historyProvider = AsyncNotifierProvider<HistoryNotifier, List<HistoryEntry>>(
  HistoryNotifier.new,
);

/// Loads and updates the calculation history.
class HistoryNotifier extends AsyncNotifier<List<HistoryEntry>> {
  @override
  Future<List<HistoryEntry>> build() =>
      ref.watch(historyRepositoryProvider).list();

  /// Adds an entry for `expression` = `result` in `mode`, timestamped now.
  ///
  /// With [keepLast], the entries beyond that many newest ones are deleted
  /// right after (the history's retention limit).
  Future<void> add({
    required String expression,
    required CalcValue result,
    required CalculatorMode mode,
    int? keepLast,
  }) async {
    final repository = ref.read(historyRepositoryProvider);
    final entry = await repository.add(
      expression: expression,
      result: result,
      mode: mode,
    );
    if (!ref.mounted) return;
    if (keepLast != null) {
      await repository.trimTo(keepLast);
      if (!ref.mounted) return;
      state = AsyncData(await repository.list());
      return;
    }
    final current = state.value ?? const [];
    state = AsyncData([entry, ...current]);
  }

  /// Deletes every entry but the [keep] newest, and shows what is left.
  Future<void> trimTo(int keep) async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.trimTo(keep);
    if (!ref.mounted) return;
    state = AsyncData(await repository.list());
  }

  /// Removes the entry with `id`.
  Future<void> delete(int id) async {
    await ref.read(historyRepositoryProvider).delete(id);
    if (!ref.mounted) return;
    final current = state.value ?? const [];
    state = AsyncData([
      for (final entry in current)
        if (entry.id != id) entry,
    ]);
  }

  /// Removes every entry.
  Future<void> clear() async {
    await ref.read(historyRepositoryProvider).clear();
    if (!ref.mounted) return;
    state = const AsyncData([]);
  }
}
