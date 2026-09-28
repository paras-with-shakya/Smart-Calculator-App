import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';

/// The mode currently shown.
///
/// Switching modes changes this state; it does not navigate.
final NotifierProvider<CurrentModeNotifier, CalculatorMode>
currentModeProvider = NotifierProvider<CurrentModeNotifier, CalculatorMode>(
  CurrentModeNotifier.new,
);

/// Holds the current [CalculatorMode]. The app starts in
/// [CalculatorMode.basic].
class CurrentModeNotifier extends Notifier<CalculatorMode> {
  @override
  CalculatorMode build() => CalculatorMode.basic;

  /// Shows [mode].
  void select(CalculatorMode mode) => state = mode;
}
