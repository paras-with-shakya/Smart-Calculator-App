/// The calculator modes, in the order the mode sheet and the navigation rail
/// list them.
///
/// This enum is the mode registry. Adding a value makes the compiler point at
/// every exhaustive switch that must handle it, such as the mode's name and
/// icon.
enum CalculatorMode { basic, scientific, programmer, finance, converter, date }

/// How a [CalculatorMode] is written to storage (history, saved
/// calculations): a fixed string, not the enum name, so renaming a value
/// never invalidates what's already saved (the same convention as
/// `ThemePreference`).
extension CalculatorModeStorage on CalculatorMode {
  /// The stable identifier stored for this mode.
  String get storageId => switch (this) {
    CalculatorMode.basic => 'basic',
    CalculatorMode.scientific => 'scientific',
    CalculatorMode.programmer => 'programmer',
    CalculatorMode.finance => 'finance',
    CalculatorMode.converter => 'converter',
    CalculatorMode.date => 'date',
  };

  /// The mode [storageId] stands for, or [CalculatorMode.basic] for an
  /// unrecognized value (matching the fallback settings use).
  static CalculatorMode fromStorageId(String storageId) =>
      CalculatorMode.values.firstWhere(
        (mode) => mode.storageId == storageId,
        orElse: () => CalculatorMode.basic,
      );
}
