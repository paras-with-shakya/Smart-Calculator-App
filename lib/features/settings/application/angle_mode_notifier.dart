import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';

/// Whether trigonometric functions work in degrees or radians.
final NotifierProvider<AngleModeNotifier, AngleMode> angleModeProvider =
    NotifierProvider<AngleModeNotifier, AngleMode>(AngleModeNotifier.new);

/// Holds the angle mode and saves every change.
class AngleModeNotifier extends Notifier<AngleMode> {
  @override
  AngleMode build() => ref.watch(settingsRepositoryProvider).angleMode;

  /// Applies [mode] at once, then saves it. The calculator reacts to the
  /// change immediately; a failed save only means the choice is not
  /// remembered after a restart.
  Future<void> setMode(AngleMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref.read(settingsRepositoryProvider).setAngleMode(mode);
  }

  /// Switches between degrees and radians.
  Future<void> toggle() => setMode(
    state == AngleMode.degrees ? AngleMode.radians : AngleMode.degrees,
  );
}
