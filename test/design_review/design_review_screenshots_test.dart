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
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/app_root.dart';
import 'package:smart_calculator/app/shell/mode_picker.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
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
}
