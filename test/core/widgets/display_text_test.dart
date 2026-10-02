import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/display_text.dart';

import '../../helpers/themed.dart';

void main() {
  const style = TextStyle(fontSize: 40, height: 1);
  const color = Color(0xFF000000);

  Future<void> pumpLine(
    WidgetTester tester,
    String text, {
    double width = 300,
    int? caretOffset,
    ValueChanged<int>? onTapOffset,
    String? semanticsLabel,
  }) => pumpThemed(
    tester,
    SizedBox(
      width: width,
      child: DisplayText(
        text,
        style: style,
        color: color,
        caretOffset: caretOffset,
        onTapOffset: onTapOffset,
        semanticsLabel: semanticsLabel,
      ),
    ),
  );

  RenderDisplayText renderOf(WidgetTester tester) =>
      tester.renderObject<RenderDisplayText>(find.byType(DisplayText));

  // The test font draws every character as a square as wide as the font
  // size, so a 40 px character is 40 px wide.
  testWidgets('short text keeps its full size, on one line', (tester) async {
    await pumpLine(tester, '12345');

    expect(renderOf(tester).fontScale, 1);
    expect(tester.getSize(find.byType(DisplayText)), const Size(300, 40));
  });

  testWidgets('longer text shrinks to stay on one line', (tester) async {
    await pumpLine(tester, '1234567890'); // 400 px at full size

    expect(renderOf(tester).fontScale, closeTo(0.75, 0.01));
    expect(tester.getSize(find.byType(DisplayText)).height, closeTo(30, 1));
  });

  group('maxLineHeight', () {
    Future<void> pumpCapped(WidgetTester tester, double? maxLineHeight) =>
        pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: DisplayText(
              '12',
              style: style,
              color: color,
              maxLineHeight: maxLineHeight,
            ),
          ),
        );

    testWidgets('shrinks a line that would be taller than it', (tester) async {
      await pumpCapped(tester, 30);

      expect(renderOf(tester).fontScale, closeTo(0.75, 0.01));
      expect(tester.getSize(find.byType(DisplayText)).height, 30);
    });

    testWidgets('changes nothing when the line already fits', (tester) async {
      await pumpCapped(tester, 80);

      expect(renderOf(tester).fontScale, 1);
    });

    testWidgets('never shrinks below minScale', (tester) async {
      await pumpCapped(tester, 4);

      expect(renderOf(tester).fontScale, 0.5);
    });
  });

  testWidgets('beyond half size it wraps instead of shrinking further', (
    tester,
  ) async {
    await pumpLine(tester, '1' * 30); // 1200 px at full size

    expect(renderOf(tester).fontScale, 0.5);
    // 20 px characters, 15 per line: two lines.
    expect(tester.getSize(find.byType(DisplayText)).height, closeTo(40, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty text keeps the height of one line', (tester) async {
    await pumpLine(tester, '');

    expect(tester.getSize(find.byType(DisplayText)).height, 40);
  });

  testWidgets('follows the text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLine(tester, '12');

    expect(tester.getSize(find.byType(DisplayText)).height, 80);
  });

  testWidgets('reports the text offset nearest a tap', (tester) async {
    final taps = <int>[];
    await pumpLine(tester, '12345', onTapOffset: taps.add);
    final box = tester.getRect(find.byType(DisplayText));

    // End-aligned: the text spans the last 200 px.
    await tester.tapAt(Offset(box.right - 195, box.center.dy));
    await tester.tapAt(Offset(box.right - 85, box.center.dy));
    await tester.tapAt(Offset(box.right - 2, box.center.dy));

    expect(taps, [0, 3, 5]);
  });

  testWidgets('ignores taps without a callback', (tester) async {
    await pumpLine(tester, '12345');

    expect(
      tester
          .hitTestOnBinding(tester.getCenter(find.byType(DisplayText)))
          .path
          .any((entry) => entry.target is RenderDisplayText),
      isFalse,
    );
  });

  testWidgets('paints a caret in the accent colour', (tester) async {
    await pumpLine(tester, '12345', caretOffset: 2);

    expect(
      find.byType(DisplayText),
      paints..rrect(color: AppColors.light.primary),
    );
  });

  testWidgets('paints no caret without an offset', (tester) async {
    await pumpLine(tester, '12345');

    expect(find.byType(DisplayText), isNot(paints..rrect()));
  });

  testWidgets('screen readers hear the semantics label', (tester) async {
    await pumpLine(tester, '5+3', semanticsLabel: '5 plus 3');

    expect(
      tester.getSemantics(find.byType(DisplayText)),
      isSemantics(label: '5 plus 3'),
    );
  });

  testWidgets('screen readers hear the text by default', (tester) async {
    await pumpLine(tester, '42');

    expect(
      tester.getSemantics(find.byType(DisplayText)),
      isSemantics(label: '42'),
    );
  });

  testWidgets('reports intrinsic sizes for its text', (tester) async {
    await pumpThemed(
      tester,
      IntrinsicWidth(
        child: DisplayText(
          '123',
          style: AppTypography.standard.result.copyWith(
            fontFamily: 'FlutterTest',
            fontSize: 40,
            height: 1,
            letterSpacing: 0,
          ),
          color: color,
        ),
      ),
    );

    expect(tester.getSize(find.byType(DisplayText)), const Size(120, 40));
  });
}
