// Runs Flutter's accessibility guidelines over every component, as shown in
// the component gallery, in all four themes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/gallery/gallery_sections.dart';

void main() {
  final themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
    'high-contrast light': AppTheme.highContrastLight,
    'high-contrast dark': AppTheme.highContrastDark,
  };

  for (final MapEntry(key: themeName, value: theme) in themes.entries) {
    group('$themeName theme', () {
      for (final section in GallerySection.values) {
        testWidgets('${section.title}: text contrast, touch targets and '
            'labels meet the guidelines', (tester) async {
          tester.view
            ..physicalSize = const Size(412, 3000)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: SingleChildScrollView(child: GallerySectionView(section)),
              ),
            ),
          );

          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        });
      }
    });
  }
}
