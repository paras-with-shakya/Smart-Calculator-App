import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/features/converter/application/converter_notifier.dart';
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

  /// The chip (its card) showing [label].
  Finder chipOf(String label) => find
      .ancestor(
        of: find.descendant(
          of: find.byType(CategoryPicker),
          matching: find.text(label),
        ),
        matching: find.byType(Material),
      )
      .first;

  testWidgets('the chips sit in one row, each at least 48 dp tall', (
    tester,
  ) async {
    await pumpConverter(tester, size: const Size(360, 800));

    final tops = {
      for (final label in labels()) tester.getTopLeft(chipOf(label)).dy,
    };
    expect(tops, hasLength(1));
    for (final label in labels()) {
      expect(
        tester.getSize(chipOf(label)).height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
        reason: label,
      );
    }
  });

  testWidgets('a saved category at the end of the row starts in view', (
    tester,
  ) async {
    await pumpConverter(tester, size: const Size(360, 800));
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(converterProvider.notifier)
        .selectCategory(ConversionCategoryId.currency);
    await tester.pumpAndSettle();

    final picker = tester.getRect(find.byType(CategoryPicker));
    final chip = tester.getRect(chipOf(l10n.converterCategoryCurrency));
    expect(chip.left, greaterThanOrEqualTo(picker.left));
    expect(chip.right, lessThanOrEqualTo(picker.right));
  });
}
