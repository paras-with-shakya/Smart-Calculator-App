import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/features/financial/domain/financial_tool.dart';
import 'package:smart_calculator/features/financial/presentation/financial_tool_picker.dart';

import '../../../helpers/real_fonts.dart';
import '../../../helpers/test_app.dart';

void main() {
  // Whether a word fits a tile depends on the glyph widths, so measure in
  // the real font (the default test font draws every glyph as a wide square).
  setUpAll(loadRealFonts);
  setUp(useInMemoryPreferences);

  Future<void> pumpFinancial(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    bool boldText = false,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    if (boldText) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(boldText: true);
    }
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await pumpApp(tester, size: size);
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(currentModeProvider.notifier)
        .select(CalculatorMode.finance);
    await tester.pumpAndSettle();
  }

  /// Every tool's label, as the picker shows it.
  List<String> labels() {
    final strings = l10n;
    return [for (final tool in FinancialToolId.values) labelFor(strings, tool)];
  }

  Finder labelText(String label) => find.descendant(
    of: find.byType(FinancialToolPicker),
    matching: find.text(label),
  );

  /// The words of [label] that are split across two or more lines.
  List<String> brokenWords(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(labelText(label));
    return [
      for (final word in RegExp(r'\S+').allMatches(label))
        if ({
              for (final box in paragraph.getBoxesForSelection(
                TextSelection(baseOffset: word.start, extentOffset: word.end),
              ))
                box.top,
            }.length >
            1)
          word.group(0)!,
    ];
  }

  group('a word in a tool label is never broken across lines', () {
    const sizes = {
      'phone portrait': Size(360, 800),
      'phone landscape': Size(800, 360),
    };

    for (final MapEntry(key: name, value: size) in sizes.entries) {
      for (final scale in [1.0, 1.15, 1.3, 2.0]) {
        testWidgets('$name, ${(scale * 100).round()}% text', (tester) async {
          await pumpFinancial(tester, size: size, textScale: scale);

          for (final label in labels()) {
            expect(brokenWords(tester, label), isEmpty, reason: label);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    // Bold text (an Android accessibility setting) draws every label wider.
    for (final scale in [1.0, 2.0]) {
      testWidgets('phone portrait, bold text, ${(scale * 100).round()}% text', (
        tester,
      ) async {
        await pumpFinancial(
          tester,
          size: const Size(360, 800),
          textScale: scale,
          boldText: true,
        );

        for (final label in labels()) {
          expect(brokenWords(tester, label), isEmpty, reason: label);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('every tile is the same width', (tester) async {
    await pumpFinancial(tester, size: const Size(360, 800));

    final widths = {
      for (final label in labels())
        tester
            .getSize(
              find
                  .ancestor(
                    of: labelText(label),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .width,
    };

    expect(widths, hasLength(1));
  });

  testWidgets('at 100% on a 360 dp phone the tiles still sit three to a row', (
    tester,
  ) async {
    await pumpFinancial(tester, size: const Size(360, 800));

    final tops = {
      for (final label in labels()) tester.getTopLeft(labelText(label)).dy,
    };

    // Seven tiles: rows of 3, 3 and 1.
    expect(tops, hasLength(3));
  });
}
