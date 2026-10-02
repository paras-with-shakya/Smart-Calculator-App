import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_sizing.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/app/theme/user_text_scaler.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';

import '../helpers/test_app.dart';

/// A scaler that is not a straight multiple, like Android 14's: it grows
/// small text more than large text.
class NonlinearScaler extends TextScaler {
  const NonlinearScaler();

  @override
  double scale(double fontSize) =>
      fontSize < 20 ? fontSize * 1.5 : fontSize + 10;

  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) => other is NonlinearScaler;

  @override
  int get hashCode => 1;
}

void main() {
  setUp(useInMemoryPreferences);

  group('UserTextScaler', () {
    test('multiplies what the system scaler returns', () {
      const scaler = UserTextScaler(TextScaler.linear(1.2), 1.3);
      expect(scaler.scale(10), closeTo(15.6, 1e-9));
      expect(scaler.scale(20), closeTo(31.2, 1e-9));
    });

    test('on top of a nonlinear system scaler, each size is scaled by it', () {
      const scaler = UserTextScaler(NonlinearScaler(), 1.15);
      // 10 -> 15 (system) -> 17.25; 40 -> 50 (system) -> 57.5, capped at 100.
      expect(scaler.scale(10), closeTo(17.25, 1e-9));
      expect(scaler.scale(40), closeTo(57.5, 1e-9));
    });

    test('the increase is capped at 2.5 times the font size', () {
      const scaler = UserTextScaler(TextScaler.linear(2), 1.3);
      expect(scaler.scale(10), 25); // 26 would be 2.6x
      expect(scaler.scale(1), 2.5);
    });

    test('a system scale above the cap is never reduced', () {
      const scaler = UserTextScaler(TextScaler.linear(3), 1.15);
      expect(scaler.scale(10), 30);
    });

    test('equal scalers are equal', () {
      const a = UserTextScaler(TextScaler.linear(1.2), 1.3);
      const b = UserTextScaler(TextScaler.linear(1.2), 1.3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const UserTextScaler(TextScaler.linear(1.2), 1.15), isFalse);
      expect(a == const UserTextScaler(TextScaler.linear(1.1), 1.3), isFalse);
    });

    test('the estimated factor is the scale of one font pixel', () {
      const scaler = UserTextScaler(TextScaler.linear(1.2), 1.3);
      // ignore: deprecated_member_use
      expect(scaler.textScaleFactor, closeTo(1.56, 1e-9));
    });
  });

  group('AppSizing', () {
    Widget host(Widget child, {double? scale}) {
      final themed = MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: child)),
      );
      return scale == null
          ? themed
          : AppSizing(controlScale: scale, child: themed);
    }

    testWidgets('is 1 with no AppSizing above', (tester) async {
      late double scale;
      late double target;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              scale = AppSizing.of(context);
              target = AppSizing.minTarget(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(scale, 1);
      expect(target, kMinInteractiveDimension);
    });

    testWidgets('AppButton grows to the scaled minimum, and no more', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AppButton(label: 'Go', onPressed: () {}, expand: false)),
      );
      final normal = tester.getSize(find.byType(FilledButton));

      await tester.pumpWidget(
        host(AppButton(label: 'Go', onPressed: () {}), scale: 1.25),
      );
      final larger = tester.getSize(find.byType(FilledButton));

      expect(normal.height, 48);
      expect(larger.height, 60);
    });

    testWidgets('every AppButton variant follows it', (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          host(
            AppButton(label: 'Go', variant: variant, onPressed: () {}),
            scale: 1.25,
          ),
        );
        final button = find.byWidgetPredicate((w) => w is ButtonStyleButton);
        expect(tester.getSize(button).height, 60, reason: '$variant');
      }
    });

    testWidgets('AppIconButton follows it', (tester) async {
      for (final variant in AppIconButtonVariant.values) {
        await tester.pumpWidget(
          host(
            AppIconButton(
              icon: Icons.add,
              tooltip: 'Add',
              variant: variant,
              onPressed: () {},
            ),
            scale: 1.25,
          ),
        );
        expect(
          tester.getSize(find.byType(IconButton)).height,
          60,
          reason: '$variant',
        );
      }
    });

    testWidgets('CalculatorButton keeps a larger minimum in a loose box', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Align(
            child: CalculatorButton(
              kind: CalculatorButtonKind.digit,
              label: '7',
              semanticLabel: '7',
              onPressed: () {},
            ),
          ),
          scale: 1.25,
        ),
      );

      final size = tester.getSize(find.byType(CalculatorButton));
      expect(size.height, greaterThanOrEqualTo(60));
      expect(size.width, greaterThanOrEqualTo(60));
    });

    testWidgets('AppChoiceGroup segments grow', (tester) async {
      Future<double> heightAt(double? scale) async {
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 320,
              child: AppChoiceGroup<int>(
                options: const [
                  AppChoice(value: 1, label: 'A'),
                  AppChoice(value: 2, label: 'B'),
                ],
                selected: 1,
                onChanged: (_) {},
              ),
            ),
            scale: scale,
          ),
        );
        return tester.getSize(find.byType(SegmentedButton<int>)).height;
      }

      final normal = await heightAt(null);
      final larger = await heightAt(1.25);

      expect(larger, greaterThan(normal));
      expect(larger, greaterThanOrEqualTo(50));
    });

    testWidgets('a scale change reaches widgets already on screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AppButton(label: 'Go', onPressed: () {}), scale: 1),
      );
      expect(tester.getSize(find.byType(FilledButton)).height, 48);

      await tester.pumpWidget(
        host(AppButton(label: 'Go', onPressed: () {}), scale: 1.25),
      );
      expect(tester.getSize(find.byType(FilledButton)).height, 60);
    });
  });

  group('in the app', () {
    late ProviderContainer container;

    Future<void> pumpAppWith(WidgetTester tester, {Size? size}) async {
      await pumpApp(tester, size: size ?? TestWindows.phonePortrait);
      container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
    }

    double scaleOf(WidgetTester tester, double fontSize) =>
        MediaQuery.of(tester.element(find.byType(Scaffold).first)).textScaler
            .scale(fontSize);

    testWidgets('the text size multiplies the system text size', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpAppWith(tester);
      expect(scaleOf(tester, 10), closeTo(12, 1e-9));

      await container
          .read(appSettingsProvider.notifier)
          .setTextSize(TextSize.larger);
      await tester.pumpAndSettle();

      expect(scaleOf(tester, 10), closeTo(15.6, 1e-9));

      await container
          .read(appSettingsProvider.notifier)
          .setTextSize(TextSize.normal);
      await tester.pumpAndSettle();
      expect(scaleOf(tester, 10), closeTo(12, 1e-9));
    });

    testWidgets('the larger text size leaves the system size alone at 100%', (
      tester,
    ) async {
      await pumpAppWith(tester);

      expect(scaleOf(tester, 10), 10);
    });

    testWidgets('larger controls grow the Converter keypad rows', (
      tester,
    ) async {
      await pumpAppWith(tester);
      container
          .read(currentModeProvider.notifier)
          .select(CalculatorMode.converter);
      await tester.pumpAndSettle();
      Finder seven() => find.byWidgetPredicate(
        (w) => w is CalculatorButton && w.label == '7',
      );
      final normal = tester.getSize(seven()).height;

      await container
          .read(appSettingsProvider.notifier)
          .setLargerControls(enabled: true);
      await tester.pumpAndSettle();
      final larger = tester.getSize(seven()).height;

      expect(larger / normal, closeTo(1.25, 0.02));
      expect(tester.takeException(), isNull);
    });

    testWidgets('larger controls do not overflow any mode, portrait or '
        'landscape, at 130% text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [
        TestWindows.phonePortrait,
        TestWindows.phoneLandscape,
      ]) {
        await pumpAppWith(tester, size: size);
        await container
            .read(appSettingsProvider.notifier)
            .setLargerControls(enabled: true);
        await container
            .read(appSettingsProvider.notifier)
            .setTextSize(TextSize.larger);
        for (final mode in CalculatorMode.values) {
          container.read(currentModeProvider.notifier).select(mode);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$mode at $size');
        }
      }
    });

    testWidgets('the top bar keeps its controls at normal size (it is a fixed '
        '56 dp tall)', (tester) async {
      await pumpAppWith(tester);
      await container
          .read(appSettingsProvider.notifier)
          .setLargerControls(enabled: true);
      await tester.pumpAndSettle();

      final pill = tester.getSize(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(FilledButton),
        ),
      );
      expect(pill.height, lessThanOrEqualTo(48)); // 60 with larger controls
      // (An icon button is 40 dp with a 48 dp touch target around it.)
      expect(
        tester.getSize(find.byTooltip(l10n.settingsTitle)).height,
        lessThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the programmer keys stay 48 dp or more with larger controls', (
      tester,
    ) async {
      await pumpAppWith(tester);
      await container
          .read(appSettingsProvider.notifier)
          .setLargerControls(enabled: true);
      container
          .read(currentModeProvider.notifier)
          .select(CalculatorMode.programmer);
      await tester.pumpAndSettle();

      for (final element in find.byType(CalculatorButton).evaluate()) {
        final box = element.renderObject! as RenderBox;
        expect(box.size.height, greaterThanOrEqualTo(60));
      }
    });

    testWidgets('high contrast forces the high-contrast colours', (
      tester,
    ) async {
      await pumpAppWith(tester);
      AppColors colors() =>
          AppColors.of(tester.element(find.byType(Scaffold).first));
      expect(colors(), same(AppColors.light));

      await container
          .read(appSettingsProvider.notifier)
          .setHighContrast(enabled: true);
      await tester.pumpAndSettle();
      expect(colors(), same(AppColors.highContrastLight));

      await container
          .read(appSettingsProvider.notifier)
          .setHighContrast(enabled: false);
      await tester.pumpAndSettle();
      expect(colors(), same(AppColors.light));
    });

    testWidgets('a device that asks for more contrast still gets it with '
        'the switch off', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpAppWith(tester);

      expect(
        AppColors.of(tester.element(find.byType(Scaffold).first)),
        same(AppColors.highContrastLight),
      );
    });

    testWidgets('the default mode applies at start, not while running', (
      tester,
    ) async {
      await pumpAppWith(tester);
      await container
          .read(appSettingsProvider.notifier)
          .setDefaultMode(CalculatorMode.date);
      await tester.pumpAndSettle();

      // Changing the default does not move the mode being shown.
      expect(container.read(currentModeProvider), CalculatorMode.basic);

      // A restart (a fresh app over the same preferences) opens in it.
      await tester.pumpWidget(const SizedBox());
      await pumpAppWith(tester);
      expect(container.read(currentModeProvider), CalculatorMode.date);
    });
  });
}
