import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

/// Reads and saves the user's settings.
abstract interface class SettingsRepository {
  /// The saved theme preference, or [ThemePreference.system] if none is saved.
  ThemePreference get themePreference;

  /// Saves [preference].
  Future<void> setThemePreference(ThemePreference preference);

  /// The saved angle mode, or [AngleMode.degrees] if none is saved.
  AngleMode get angleMode;

  /// Saves [mode].
  Future<void> setAngleMode(AngleMode mode);
}
