import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/features/calculator/data/preferences_memory_repository.dart';

/// The calculator memory: null when empty. It is saved on every change, so
/// it survives restarts, and it is independent of the display.
final NotifierProvider<MemoryNotifier, CalcValue?> memoryProvider =
    NotifierProvider<MemoryNotifier, CalcValue?>(MemoryNotifier.new);

/// Holds and saves the calculator memory.
class MemoryNotifier extends Notifier<CalcValue?> {
  @override
  CalcValue? build() => ref.watch(memoryRepositoryProvider).read();

  /// MC: empties the memory.
  Future<void> clear() => _save(null);

  /// MS: replaces the memory with [value].
  Future<void> store(CalcValue value) => _save(value);

  /// M+: adds [value] to the memory (an empty memory counts as zero).
  Future<void> add(CalcValue value) => _save((state ?? CalcValue.zero) + value);

  /// M−: subtracts [value] from the memory.
  Future<void> subtract(CalcValue value) =>
      _save((state ?? CalcValue.zero) - value);

  /// Saves [value], then applies it. A value too large to show is refused,
  /// so the memory stays as it was.
  Future<void> _save(CalcValue? value) async {
    if (value != null && value.isTooLarge) return;
    await ref.read(memoryRepositoryProvider).write(value);
    if (!ref.mounted) return;
    state = value;
  }
}
