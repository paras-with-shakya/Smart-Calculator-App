import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/core/feedback/key_feedback.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';

/// The press feedback the user's settings ask for.
///
/// Read it when a key is pressed (`ref.read(keyFeedbackProvider).key()`), not
/// while building, so a change in Settings applies to the very next press.
final Provider<KeyFeedback> keyFeedbackProvider = Provider<KeyFeedback>(
  (ref) => KeyFeedback(
    haptics: ref.watch(appSettingsProvider.select((s) => s.haptics)),
    sound: ref.watch(appSettingsProvider.select((s) => s.keySound)),
  ),
);
