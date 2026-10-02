import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The system's text scaling with the in-app text size on top of it.
///
/// It multiplies whatever the system's scaler returns for a font size, so it
/// is right for the nonlinear scalers of Android 14 and later too (the
/// system scale is never read as a single number). The increase is capped so
/// that text is never more than [maxFactor] times its size, but it is never
/// reduced below what the system alone would give.
final class UserTextScaler extends TextScaler {
  /// Scales by [multiplier] on top of [system].
  const UserTextScaler(this.system, this.multiplier, {this.maxFactor = 2.5});

  /// The system's text scaling.
  final TextScaler system;

  /// What the system's scaled size is multiplied by.
  final double multiplier;

  /// The most the combined scaling may reach, as a factor of the font size.
  final double maxFactor;

  @override
  double scale(double fontSize) {
    final base = system.scale(fontSize);
    final cap = math.max(base, fontSize * maxFactor);
    return math.min(base * multiplier, cap);
  }

  // Required by TextScaler; only an estimate, as its own documentation says.
  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is UserTextScaler &&
      other.system == system &&
      other.multiplier == multiplier &&
      other.maxFactor == maxFactor;

  @override
  int get hashCode => Object.hash(system, multiplier, maxFactor);

  @override
  String toString() => 'UserTextScaler($system x $multiplier, max $maxFactor)';
}
