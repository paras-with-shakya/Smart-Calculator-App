import 'package:calc_engine/calc_engine.dart';

/// Reads and saves the calculator's memory (MC, MR, M+, M−, MS).
abstract interface class MemoryRepository {
  /// The saved memory, or null if the memory is empty.
  CalcValue? read();

  /// Saves [value], or clears the memory when it is null.
  Future<void> write(CalcValue? value);
}
