import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/converter/presentation/category_picker.dart';

import '../../../helpers/real_fonts.dart';
import '../../../helpers/test_app.dart';

void main() {
  // Whether a label fits a tile depends on the glyph widths, so measure in
  // the real font (the default test font draws every glyph as a wide square).
  setUpAll(loadRealFonts);
  setUp(useInMemoryPreferences);

  Future<void> pumpConverter(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await pumpApp(tester, size: size);
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(currentModeProvider.notifier)
        .select(CalculatorMode.converter);
    await tester.pumpAndSettle();
  }

  /// Every category's label, as the picker shows it.
  List<String> labels() {
    final strings = l10n;
    return [
      for (final category in ConversionCategoryId.values)
        labelFor(strings, category),
    ];
  }

  /// How many lines [label] is drawn on inside the picker.
  int linesOf(WidgetTester tester, String label) {
    final finder = find.descendant(
      of: find.byType(CategoryPicker),
      matching: find.text(label),
    );
    final paragraph = tester.renderObject<RenderParagraph>(finder);
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: 0,
        extentOffset: paragraph.text.toPlainText().length,
      ),
    );
    return {for (final box in boxes) box.top}.length;
  }

  group('a category label is never broken across lines', () {
    const sizes = {
      'phone portrait': Size(360, 800),
      'phone landscape': Size(800, 360),
    };

    for (final MapEntry(key: name, value: size) in sizes.entries) {
      for (final scale in [1.0, 1.15, 1.3, 2.0]) {
        testWidgets('$name, ${(scale * 100).round()}% text', (tester) async {
          await pumpConverter(tester, size: size, textScale: scale);

          for (final label in labels()) {
            expect(linesOf(tester, label), 1, reason: label);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('every tile is the same size', (tester) async {
    await pumpConverter(tester, size: const Size(360, 800));

    final sizes = {
      for (final label in labels())
        tester.getSize(
          find
              .ancestor(
                of: find.descendant(
                  of: find.byType(CategoryPicker),
                  matching: find.text(label),
                ),
                matching: find.byType(Material),
              )
              .first,
        ),
    };

    expect(sizes, hasLength(1));
  });

  testWidgets('at 100% on a 360 dp phone the tiles still sit three to a row', (
    tester,
  ) async {
    await pumpConverter(tester, size: const Size(360, 800));

    final tops = {
      for (final label in labels())
        tester
            .getTopLeft(
              find.descendant(
                of: find.byType(CategoryPicker),
                matching: find.text(label),
              ),
            )
            .dy,
    };

    // Seven tiles: rows of 3, 3 and 1.
    expect(tops, hasLength(3));
  });
}
