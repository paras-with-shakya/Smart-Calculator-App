// Renders the design-review screenshots: every gallery section and the main
// app screens, with the real fonts, in light, dark and high contrast.
//
// It is skipped by the normal test run (see dart_test.yaml). Generate the
// images with:
//
//     flutter test --tags design-review --run-skipped --update-goldens
//
// They are written to build/design_review/ and are not committed; they are
// rendered on this machine for review, not compared across machines.
@Tags(['design-review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/app_root.dart';
import 'package:smart_calculator/app/shell/mode_picker.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_view.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';
import 'package:smart_calculator/gallery/gallery_sections.dart';

import '../helpers/real_fonts.dart';
import '../helpers/test_app.dart';

const Key _capture = ValueKey('design-review-capture');

String _file(String name) => '../../build/design_review/$name.png';

void main() {
  setUpAll(() async {
    await loadRealFonts();
    // The debug banner would cover the top-right corner of every screen.
    WidgetsApp.debugAllowBannerOverride = false;
  });
  tearDownAll(() => WidgetsApp.debugAllowBannerOverride = true);

  Future<void> captureSection(
    WidgetTester tester,
    GallerySection section,
    ThemeData theme,
    String name, {
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(412, 3200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: _capture,
              child: Material(
                color: theme.extension<AppColors>()!.background,
                child: GallerySectionView(section),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byKey(_capture), matchesGoldenFile(_file(name)));
  }

  final themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
    'hc-light': AppTheme.highContrastLight,
    'hc-dark': AppTheme.highContrastDark,
  };

  for (final section in GallerySection.values) {
    for (final themeName in ['light', 'dark']) {
      testWidgets('gallery ${section.name} ($themeName)', (tester) async {
        await captureSection(
          tester,
          section,
          themes[themeName]!,
          'gallery_${section.name}_$themeName',
        );
      });
    }
  }

  for (final section in [
    GallerySection.buttons,
    GallerySection.keys,
    GallerySection.cards,
    GallerySection.inputs,
    GallerySection.states,
  ]) {
    testWidgets('gallery ${section.name} (light, 200% text)', (tester) async {
      await captureSection(
        tester,
        section,
        AppTheme.light,
        'gallery_${section.name}_light_text200',
        textScale: 2,
      );
    });
  }

  for (final section in [GallerySection.buttons, GallerySection.keys]) {
    for (final themeName in ['hc-light', 'hc-dark']) {
      testWidgets('gallery ${section.name} ($themeName)', (tester) async {
        await captureSection(
          tester,
          section,
          themes[themeName]!,
          'gallery_${section.name}_$themeName',
        );
      });
    }
  }

  group('app screens', () {
    setUp(useInMemoryPreferences);

    Future<void> pumpAppScreen(
      WidgetTester tester, {
      required Size size,
      ThemePreference theme = ThemePreference.light,
    }) async {
      final preferences = await openPreferences();
      await PreferencesSettingsRepository(preferences)
          .setThemePreference(theme);
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _capture,
          child: AppRoot(preferences: preferences),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final theme in [ThemePreference.light, ThemePreference.dark]) {
      testWidgets('phone shell (${theme.name})', (tester) async {
        await pumpAppScreen(
          tester,
          size: TestWindows.phonePortrait,
          theme: theme,
        );
        await expectLater(
          find.byKey(_capture),
          matchesGoldenFile(_file('app_phone_shell_${theme.name}')),
        );
      });

      testWidgets('phone mode sheet (${theme.name})', (tester) async {
        await pumpAppScreen(
          tester,
          size: TestWindows.phonePortrait,
          theme: theme,
        );
        await tester.tap(find.byType(ModePickerButton));
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(_capture),
          matchesGoldenFile(_file('app_phone_mode_sheet_${theme.name}')),
        );
      });
    }

    testWidgets('phone settings (dark)', (tester) async {
      await pumpAppScreen(
        tester,
        size: TestWindows.phonePortrait,
        theme: ThemePreference.dark,
      );
      await tester.tap(find.byTooltip(l10n.settingsTitle));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(_capture),
        matchesGoldenFile(_file('app_phone_settings_dark')),
      );
    });

    testWidgets('tablet landscape shell (light)', (tester) async {
      await pumpAppScreen(tester, size: TestWindows.tabletLandscape);
      await expectLater(
        find.byKey(_capture),
        matchesGoldenFile(_file('app_tablet_landscape_light')),
      );
    });
  });

  group('calculator', () {
    setUp(useInMemoryPreferences);

    // The user's phone: 360 x 800 dp, region India.
    const phone = Size(360, 800);
    const phoneLandscape = Size(800, 360);

    Future<void> pumpCalculator(
      WidgetTester tester, {
      Size size = phone,
      ThemePreference theme = ThemePreference.light,
      double textScale = 1,
      String typed = '',
      int? cursor,
      String memory = '',
    }) async {
      tester.platformDispatcher.localeTestValue = const Locale('en', 'IN');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final preferences = await openPreferences();
      await PreferencesSettingsRepository(preferences)
          .setThemePreference(theme);
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _capture,
          child: AppRoot(preferences: preferences),
        ),
      );
      await tester.pumpAndSettle();
      final calculator = ProviderScope.containerOf(
        tester.element(find.byType(CalculatorView)),
      ).read(calculatorProvider.notifier);
      if (memory.isNotEmpty) {
        calculator.typeText(memory);
        await calculator.memoryStore();
        calculator.press(CalculatorKey.allClear);
      }
      calculator.typeText(typed);
      if (cursor != null) calculator.setCursor(cursor);
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) =>
        expectLater(find.byKey(_capture), matchesGoldenFile(_file(name)));

    for (final theme in [ThemePreference.light, ThemePreference.dark]) {
      testWidgets('empty (${theme.name})', (tester) async {
        await pumpCalculator(tester, theme: theme);
        await capture('calc_phone_empty_${theme.name}');
      });

      testWidgets('typing, with memory (${theme.name})', (tester) async {
        await pumpCalculator(
          tester,
          theme: theme,
          typed: '1234567×8+90',
          memory: '2500',
        );
        await capture('calc_phone_typing_${theme.name}');
      });

      testWidgets('result (${theme.name})', (tester) async {
        await pumpCalculator(tester, theme: theme, typed: '1234567.89×12=');
        await capture('calc_phone_result_${theme.name}');
      });

      testWidgets('landscape (${theme.name})', (tester) async {
        await pumpCalculator(
          tester,
          size: phoneLandscape,
          theme: theme,
          typed: '(250+75)×4',
        );
        await capture('calc_phone_landscape_${theme.name}');
      });
    }

    testWidgets('error (light)', (tester) async {
      await pumpCalculator(tester, typed: '125÷(5−5)=');
      await capture('calc_phone_error_light');
    });

    testWidgets('cursor in the middle (light)', (tester) async {
      await pumpCalculator(tester, typed: '12345+678', cursor: 3);
      await capture('calc_phone_cursor_light');
    });

    testWidgets('long expression shrinks, then wraps (light)', (tester) async {
      await pumpCalculator(
        tester,
        typed: '123456789012345×987654321098765+12345',
      );
      await capture('calc_phone_long_light');
    });

    testWidgets('scientific notation (dark)', (tester) async {
      await pumpCalculator(
        tester,
        theme: ThemePreference.dark,
        typed: '999999999×999999999×999999=',
      );
      await capture('calc_phone_scientific_dark');
    });

    testWidgets('200% text (light)', (tester) async {
      await pumpCalculator(
        tester,
        textScale: 2,
        typed: '1234×5+6',
        memory: '7',
      );
      await capture('calc_phone_text200_light');
    });

    testWidgets('tablet portrait (light)', (tester) async {
      await pumpCalculator(
        tester,
        size: TestWindows.tabletPortrait,
        typed: '48000×18%=',
      );
      await capture('calc_tablet_portrait_light');
    });

    testWidgets('tablet landscape (dark)', (tester) async {
      await pumpCalculator(
        tester,
        size: TestWindows.tabletLandscape,
        theme: ThemePreference.dark,
        typed: '48000+18%',
      );
      await capture('calc_tablet_landscape_dark');
    });
  });
}
