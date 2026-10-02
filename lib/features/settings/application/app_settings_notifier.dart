import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';
import 'package:smart_calculator/features/settings/domain/settings_repository.dart';

/// Every setting except the theme and the angle mode (which keep their own
/// providers).
///
/// Read one field with `select` so a widget rebuilds only when that field
/// changes: `ref.watch(appSettingsProvider.select((s) => s.haptics))`.
final NotifierProvider<AppSettingsNotifier, AppSettings> appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

/// Holds [AppSettings] and saves every change.
///
/// Each setter saves first and only then updates the state, so what is
/// shown is never ahead of what is stored. The new state is built from the
/// state *after* the save, so two quick changes cannot overwrite each other.
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).appSettings;

  /// Sets the mode the app opens in. It does not switch the mode now shown.
  Future<void> setDefaultMode(CalculatorMode mode) => _set(
    mode != state.defaultMode,
    (repository) => repository.setDefaultMode(mode),
    (settings) => settings.copyWith(defaultMode: mode),
  );

  /// Turns the haptic tick on or off.
  Future<void> setHaptics({required bool enabled}) => _set(
    enabled != state.haptics,
    (repository) => repository.setHaptics(enabled: enabled),
    (settings) => settings.copyWith(haptics: enabled),
  );

  /// Turns the calculator keys' click sound on or off.
  Future<void> setKeySound({required bool enabled}) => _set(
    enabled != state.keySound,
    (repository) => repository.setKeySound(enabled: enabled),
    (settings) => settings.copyWith(keySound: enabled),
  );

  /// Sets how many places results are rounded to.
  Future<void> setDecimalPlaces(DecimalPlaces places) => _set(
    places != state.decimalPlaces,
    (repository) => repository.setDecimalPlaces(places),
    (settings) => settings.copyWith(decimalPlaces: places),
  );

  /// Turns saving new calculations to the history on or off.
  Future<void> setHistoryEnabled({required bool enabled}) => _set(
    enabled != state.historyEnabled,
    (repository) => repository.setHistoryEnabled(enabled: enabled),
    (settings) => settings.copyWith(historyEnabled: enabled),
  );

  /// Sets how many history entries are kept. This only records the choice;
  /// deleting the entries beyond it is the history's job.
  Future<void> setHistoryLimit(HistoryLimit limit) => _set(
    limit != state.historyLimit,
    (repository) => repository.setHistoryLimit(limit),
    (settings) => settings.copyWith(historyLimit: limit),
  );

  /// Sets the in-app text size.
  Future<void> setTextSize(TextSize size) => _set(
    size != state.textSize,
    (repository) => repository.setTextSize(size),
    (settings) => settings.copyWith(textSize: size),
  );

  /// Turns larger controls on or off.
  Future<void> setLargerControls({required bool enabled}) => _set(
    enabled != state.largerControls,
    (repository) => repository.setLargerControls(enabled: enabled),
    (settings) => settings.copyWith(largerControls: enabled),
  );

  /// Turns the forced high-contrast theme on or off.
  Future<void> setHighContrast({required bool enabled}) => _set(
    enabled != state.highContrast,
    (repository) => repository.setHighContrast(enabled: enabled),
    (settings) => settings.copyWith(highContrast: enabled),
  );

  Future<void> _set(
    bool changed,
    Future<void> Function(SettingsRepository repository) save,
    AppSettings Function(AppSettings settings) apply,
  ) async {
    if (!changed) return;
    await save(ref.read(settingsRepositoryProvider));
    if (!ref.mounted) return;
    state = apply(state);
  }
}
