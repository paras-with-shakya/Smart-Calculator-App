import 'package:flutter/material.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

/// Maps the user's theme choice to Flutter's [ThemeMode].
extension ThemePreferenceMode on ThemePreference {
  /// The [ThemeMode] that applies this preference.
  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
}
