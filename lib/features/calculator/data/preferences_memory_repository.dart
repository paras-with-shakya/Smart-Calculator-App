import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/calculator/domain/memory_repository.dart';

/// The app's [MemoryRepository], backed by the preloaded preferences.
final Provider<MemoryRepository> memoryRepositoryProvider =
    Provider<MemoryRepository>(
      (ref) =>
          PreferencesMemoryRepository(ref.watch(sharedPreferencesProvider)),
    );

/// Stores the memory in [SharedPreferencesWithCache] as an exact fraction,
/// so a recalled value is exactly the stored one.
final class PreferencesMemoryRepository implements MemoryRepository {
  /// Creates a repository that reads and writes [_preferences].
  const PreferencesMemoryRepository(this._preferences);

  final SharedPreferencesWithCache _preferences;

  @override
  CalcValue? read() {
    final stored = _preferences.getString(PreferenceKeys.calculatorMemory);
    return stored == null ? null : CalcValue.tryParseStorage(stored);
  }

  @override
  Future<void> write(CalcValue? value) => value == null
      ? _preferences.remove(PreferenceKeys.calculatorMemory)
      : _preferences.setString(
          PreferenceKeys.calculatorMemory,
          value.toStorageString(),
        );
}
