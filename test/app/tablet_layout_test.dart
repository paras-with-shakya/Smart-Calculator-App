// Tablet sizes for the screens whose own tests only cover phones, and the
// History page's width (Phase 11's tablet pass).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/core/layout/layout_limits.dart';
import 'package:smart_calculator/features/date_calculator/presentation/date_calculator_view.dart';
import 'package:smart_calculator/features/history/presentation/history_content.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_keypad.dart';

import '../helpers/test_app.dart';
import '../helpers/touch_targets.dart';

void main() {
  setUp(useInMemoryPreferences);

  const tablets = {
    'tablet portrait': TestWindows.tabletPortrait,
    'tablet landscape': TestWindows.tabletLandscape,
  };

  Future<void> pumpMode(
    WidgetTester tester,
    CalculatorMode mode,
    Size size,
  ) async {
    await pumpApp(tester, size: size);
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(currentModeProvider.notifier)
        .select(mode);
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: size) in tablets.entries) {
    testWidgets('Programmer on a $name: keys at least 48 dp, keypad no '
        'wider than the content limit', (tester) async {
      await pumpMode(tester, CalculatorMode.programmer, size);

      expect(tester.takeException(), isNull);
      expectTouchTargets(tester);
      expect(
        tester.getSize(find.byType(ProgrammerKeypad)).width,
        lessThanOrEqualTo(LayoutLimits.maxContentWidth),
      );
    });

    testWidgets('Date on a $name: one centred column no wider than the '
        'content limit', (tester) async {
      await pumpMode(tester, CalculatorMode.date, size);

      expect(tester.takeException(), isNull);
      final column = tester.getRect(
        find
            .descendant(
              of: find.byType(DateCalculatorView),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(column.width, lessThanOrEqualTo(LayoutLimits.maxContentWidth));
      final view = tester.getRect(find.byType(DateCalculatorView));
      expect(column.center.dx, closeTo(view.center.dx, 1));
    });
  }

  testWidgets('the History page on a tablet is a centred column, so actions '
      'stay next to their entry', (tester) async {
    await pumpApp(tester, size: TestWindows.tabletPortrait);
    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();

    final content = tester.getRect(find.byType(HistoryContent));
    expect(content.width, LayoutLimits.maxContentWidth);
    expect(content.center.dx, closeTo(TestWindows.tabletPortrait.width / 2, 1));
  });
}
