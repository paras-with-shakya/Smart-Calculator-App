import 'package:flutter/services.dart';

/// The tick and click the app gives for presses, as the user's settings
/// allow.
///
/// Calculator keys are silent on their own (`CalculatorButton` turns the
/// Material click off), so this is the only place a key press makes a haptic
/// tick or a sound. Other controls (menus, pickers, switches) keep the
/// platform's default feedback, which follows the device's own settings.
final class KeyFeedback {
  /// Creates feedback that ticks if [haptics] and clicks if [sound].
  const KeyFeedback({required this.haptics, required this.sound});

  /// Whether presses give a haptic tick.
  final bool haptics;

  /// Whether calculator keys make the system click sound. The platform
  /// still decides whether it is audible: it follows the device's
  /// touch-sounds setting.
  final bool sound;

  /// A calculator key was pressed: a light tick and the key click.
  void key() {
    select();
    if (sound) SystemSound.play(SystemSoundType.click);
  }

  /// Something was chosen (a tool, a category, a unit): a light tick, no
  /// click.
  void select() {
    if (haptics) HapticFeedback.selectionClick();
  }

  /// A press that does something big (holding backspace to clear): a firmer
  /// tick, no click.
  void heavy() {
    if (haptics) HapticFeedback.mediumImpact();
  }
}
