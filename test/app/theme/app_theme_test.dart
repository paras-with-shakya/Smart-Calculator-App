import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/shell/app_shell.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_motion.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

import '../../helpers/test_app.dart';

void main() {
  final themes = <String, (ThemeData, AppColors)>{
    'light': (AppTheme.light, AppColors.light),
    'dark': (AppTheme.dark, AppColors.dark),
    'high-contrast light': (
      AppTheme.highContrastLight,
      AppColors.highContrastLight,
    ),
    'high-contrast dark': (
      AppTheme.highContrastDark,
      AppColors.highContrastDark,
    ),
  };

  for (final MapEntry(key: name, value: (theme, palette)) in themes.entries) {
    test('the $name theme uses Manrope and carries its tokens', () {
      expect(theme.textTheme.bodyLarge!.fontFamily, AppTypography.fontFamily);
      expect(theme.textTheme.titleLarge!.fontFamily, AppTypography.fontFamily);
      expect(theme.extension<AppColors>(), same(palette));
      expect(theme.extension<AppTypography>(), same(AppTypography.standard));
      expect(theme.scaffoldBackgroundColor, palette.background);
      expect(theme.colorScheme.primary, palette.primary);
      expect(theme.colorScheme.onSurface, palette.textPrimary);
    });
  }

  test('number styles use tabular figures; running text does not', () {
    const t = AppTypography.standard;
    for (final style in [t.result, t.expression, t.display, t.key]) {
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
    for (final style in [t.body, t.heading, t.label]) {
      expect(style.fontFeatures, isNull);
    }
  });

  testWidgets('the app switches to the high-contrast theme when the platform '
      'asks for more contrast', (tester) async {
    useInMemoryPreferences();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpApp(tester);

    expect(
      AppColors.of(tester.element(find.byType(AppShell))),
      same(AppColors.highContrastLight),
    );
  });

  testWidgets('AppMotion.durationOf is zero when reduced motion is on', (
    tester,
  ) async {
    late Duration normal;
    late Duration reduced;
    await tester.pumpWidget(
      Column(
        children: [
          Builder(
            builder: (context) {
              normal = AppMotion.durationOf(context, AppMotion.medium);
              return const SizedBox();
            },
          ),
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = AppMotion.durationOf(context, AppMotion.medium);
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );

    expect(normal, AppMotion.medium);
    expect(reduced, Duration.zero);
  });
}
