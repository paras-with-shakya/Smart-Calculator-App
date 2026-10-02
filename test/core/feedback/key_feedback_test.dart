import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/feedback/key_feedback.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> calls;

  setUp(() {
    useInMemoryPreferences();
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add('haptic:${call.arguments}');
          } else if (call.method == 'SystemSound.play') {
            calls.add('sound:${call.arguments}');
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
  });

  group('KeyFeedback', () {
    test('a key press ticks and clicks', () {
      const KeyFeedback(haptics: true, sound: true).key();

      expect(calls, [
        'haptic:HapticFeedbackType.selectionClick',
        'sound:SystemSoundType.click',
      ]);
    });

    test('haptics off leaves only the click', () {
      const KeyFeedback(haptics: false, sound: true).key();

      expect(calls, ['sound:SystemSoundType.click']);
    });

    test('sound off leaves only the tick', () {
      const KeyFeedback(haptics: true, sound: false).key();

      expect(calls, ['haptic:HapticFeedbackType.selectionClick']);
    });

    test('both off is silent', () {
      const feedback = KeyFeedback(haptics: false, sound: false);
      feedback
        ..key()
        ..select()
        ..heavy();

      expect(calls, isEmpty);
    });

    test('choosing something ticks but never clicks', () {
      const KeyFeedback(haptics: true, sound: true).select();

      expect(calls, ['haptic:HapticFeedbackType.selectionClick']);
    });

    test('a long press is a firmer tick and never clicks', () {
      const KeyFeedback(haptics: true, sound: true).heavy();

      expect(calls, ['haptic:HapticFeedbackType.mediumImpact']);
    });

    test('haptics off silences the firm tick too', () {
      const KeyFeedback(haptics: false, sound: true).heavy();

      expect(calls, isEmpty);
    });
  });

  group('keyFeedbackProvider follows the settings', () {
    late SharedPreferencesWithCache preferences;

    setUp(() async {
      preferences = await openPreferences();
    });

    ProviderContainer container() => ProviderContainer.test(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );

    test('on by default', () {
      final feedback = container().read(keyFeedbackProvider);
      expect(feedback.haptics, isTrue);
      expect(feedback.sound, isTrue);
    });

    test('a change applies to the very next read', () async {
      final c = container();
      expect(c.read(keyFeedbackProvider).haptics, isTrue);

      await c.read(appSettingsProvider.notifier).setHaptics(enabled: false);
      expect(c.read(keyFeedbackProvider).haptics, isFalse);
      expect(c.read(keyFeedbackProvider).sound, isTrue);

      await c.read(appSettingsProvider.notifier).setKeySound(enabled: false);
      expect(c.read(keyFeedbackProvider).sound, isFalse);
    });
  });

  group('CalculatorButton', () {
    testWidgets('a tap makes no feedback of its own', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: CalculatorButton(
                  kind: CalculatorButtonKind.digit,
                  label: '7',
                  semanticLabel: '7',
                  onPressed: () => pressed++,
                  onLongPress: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CalculatorButton));
      await tester.pump();
      await tester.longPress(find.byType(CalculatorButton));
      await tester.pump();

      expect(pressed, 1);
      // A bare InkWell would send SystemSound.play on a tap and
      // HapticFeedback.vibrate on a long press (the platform default).
      expect(calls, isEmpty);
    });
  });
}
