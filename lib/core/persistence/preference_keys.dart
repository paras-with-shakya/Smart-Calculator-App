/// Keys of every value the app keeps in shared preferences.
///
/// [all] is also the preferences cache allow-list: a key missing from it can
/// be neither read nor written.
abstract final class PreferenceKeys {
  /// The theme the user chose: system, light or dark.
  static const String themePreference = 'settings.theme_preference';

  /// The calculator memory, as an exact fraction (`CalcValue`'s storage
  /// form). Absent when the memory is empty.
  static const String calculatorMemory = 'calculator.memory';

  /// Every key above.
  static const Set<String> all = {themePreference, calculatorMemory};
}
