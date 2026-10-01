import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/widgets/key_grid.dart';

void main() {
  Widget cell(String label) => ColoredBox(
    key: ValueKey(label),
    color: Colors.blue,
    child: Text(label, textDirection: TextDirection.ltr),
  );

  Widget host(Widget child, {double? height}) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 304, height: height, child: child),
    ),
  );

  testWidgets('with a row height, rows are that tall and the grid wraps them', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KeyGrid(
          rowHeight: 48,
          gap: 8,
          rows: [
            [cell('a'), cell('b'), cell('c')],
            [cell('d'), cell('e'), cell('f')],
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byType(KeyGrid)).height, 48 + 8 + 48);
    expect(tester.getSize(find.byKey(const ValueKey('a'))).height, 48);
    expect(KeyGrid.heightOf(2, 48, 8), 104);
  });

  testWidgets('cells share the width equally, with the gap between', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KeyGrid(
          rowHeight: 40,
          gap: 8,
          rows: [
            [cell('a'), cell('b'), cell('c')],
          ],
        ),
      ),
    );

    // (304 - 2 * 8) / 3 = 96.
    for (final label in ['a', 'b', 'c']) {
      expect(tester.getSize(find.byKey(ValueKey(label))).width, 96);
    }
    expect(tester.getTopLeft(find.byKey(const ValueKey('b'))).dx, 96 + 8);
    expect(tester.getTopLeft(find.byKey(const ValueKey('c'))).dx, 2 * (96 + 8));
  });

  testWidgets('without a row height, rows share the height given', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KeyGrid(
          gap: 8,
          rows: [
            [cell('a')],
            [cell('b')],
            [cell('c')],
          ],
        ),
        height: 224,
      ),
    );

    // (224 - 2 * 8) / 3, shared equally.
    final heights = [
      for (final label in ['a', 'b', 'c'])
        tester.getSize(find.byKey(ValueKey(label))).height,
    ];
    expect(heights, everyElement(closeTo(208 / 3, 0.01)));
  });
}
