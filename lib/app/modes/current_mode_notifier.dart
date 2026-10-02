import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';

/// The mode currently shown.
///
/// Switching modes changes this state; it does not navigate.
final NotifierProvider<CurrentModeNotifier, CalculatorMode>
currentModeProvider = NotifierProvider<CurrentModeNotifier, CalculatorMode>(
  CurrentModeNotifier.new,
);

/// Holds the current [CalculatorMode]. The app starts in the mode chosen in
/// Settings as the default ([CalculatorMode.basic] until it is changed).
class CurrentModeNotifier extends Notifier<CalculatorMode> {
  /// Read, not watched: changing the default in Settings applies at the next
  /// start; it must not switch the mode the user is looking at.
  @override
  CalculatorMode build() => ref.read(appSettingsProvider).defaultMode;

  /// Shows [mode].
  void select(CalculatorMode mode) => state = mode;
}
