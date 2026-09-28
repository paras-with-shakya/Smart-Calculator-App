import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

/// The user's current theme preference.
final NotifierProvider<ThemePreferenceNotifier, ThemePreference>
themePreferenceProvider =
    NotifierProvider<ThemePreferenceNotifier, ThemePreference>(
      ThemePreferenceNotifier.new,
    );

/// Holds the theme preference and saves every change.
class ThemePreferenceNotifier extends Notifier<ThemePreference> {
  @override
  ThemePreference build() =>
      ref.watch(settingsRepositoryProvider).themePreference;

  /// Saves [preference], then applies it.
  Future<void> setPreference(ThemePreference preference) async {
    if (preference == state) return;
    await ref.read(settingsRepositoryProvider).setThemePreference(preference);
    if (!ref.mounted) return;
    state = preference;
  }
}
