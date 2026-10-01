import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/share_of_whole_bar.dart';
import 'package:smart_calculator/features/financial/presentation/financial_tool_picker.dart';
import 'package:smart_calculator/features/financial/presentation/financial_view.dart';

import '../../../helpers/test_app.dart';

const Size phone = Size(360, 800);
const Size phoneLandscape = Size(800, 360);

Finder fieldLabeled(String label) => find.byWidgetPredicate(
  (widget) => widget is AppTextField && widget.label == label,
);

void expectCardTouchTargets(WidgetTester tester) {
  for (final element in find.byType(AppCard).evaluate()) {
    final size = (element.renderObject! as RenderBox).size;
    expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
  }
}

void main() {
  setUp(useInMemoryPreferences);

  Future<void> pumpFinancial(WidgetTester tester, {Size size = phone}) async {
    await pumpApp(tester, size: size);
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(currentModeProvider.notifier)
        .select(CalculatorMode.finance);
    await tester.pumpAndSettle();
  }

  Future<void> typeInto(WidgetTester tester, String label, String text) async {
    final field = fieldLabeled(label);
    await tester.ensureVisible(field);
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      text,
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectTool(WidgetTester tester, String label) async {
    final tile = find.text(label);
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('portrait: renders the picker and the default EMI tool', (
      tester,
    ) async {
      await pumpFinancial(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(FinancialView), findsOneWidget);
      expect(find.byType(FinancialToolPicker), findsOneWidget);
      expect(find.text('EMI'), findsWidgets);
      expectCardTouchTargets(tester);
    });

    testWidgets('landscape: renders with no overflow', (tester) async {
      await pumpFinancial(tester, size: phoneLandscape);

      expect(tester.takeException(), isNull);
      expectCardTouchTargets(tester);
    });

    for (final (name, size) in [
      ('phone portrait', phone),
      ('phone landscape', phoneLandscape),
      ('tablet portrait', TestWindows.tabletPortrait),
      ('tablet landscape', TestWindows.tabletLandscape),
    ]) {
      testWidgets('$name fits at 200% text', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpFinancial(tester, size: size);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('tool picker', () {
    testWidgets('switches tools, and remembers the choice across a restart', (
      tester,
    ) async {
      await pumpFinancial(tester);

      await selectTool(tester, 'GST');
      expect(fieldLabeled('Amount'), findsOneWidget);

      // useInMemoryPreferences() (in setUp) means every openPreferences()
      // call shares one in-memory store, so simply pumping the app again
      // simulates a restart: it should reopen on GST, not the EMI default.
      await pumpFinancial(tester);

      expect(fieldLabeled('Amount'), findsOneWidget);
    });
  });

  group('EMI', () {
    testWidgets(
      'the classic reference example (P=100000, 10%, 12 months) matches '
      'to the cent, and the share-of-whole bar appears',
      (tester) async {
        await pumpFinancial(tester);

        await typeInto(tester, 'Loan amount', '100000');
        await typeInto(tester, 'Interest rate (annual)', '10');
        await typeInto(tester, 'Tenure', '12');
        // Default tenure unit is Years, so 12 means 12 years = 144 months;
        // switch to Months for the classic 12-month example.
        await tester.tap(find.text('Months'));
        await tester.pumpAndSettle();

        expect(find.text('₹ 8,791.59'), findsOneWidget);
        expect(find.byType(ShareOfWholeBar), findsOneWidget);
      },
    );

    testWidgets('shows a validation error for an out-of-range rate', (
      tester,
    ) async {
      await pumpFinancial(tester);

      await typeInto(tester, 'Loan amount', '100000');
      await typeInto(tester, 'Interest rate (annual)', '1000.01');
      await typeInto(tester, 'Tenure', '1');

      expect(find.text('Enter at most 1000'), findsOneWidget);
    });

    testWidgets('shows a placeholder until every field is filled', (
      tester,
    ) async {
      await pumpFinancial(tester);

      expect(
        find.text('Enter every amount above to see a result.'),
        findsOneWidget,
      );
    });
  });

  group('simple interest', () {
    testWidgets('10000 at 5% for 2 years gives 1000 interest', (tester) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'Simple interest');

      await typeInto(tester, 'Principal', '10000');
      await typeInto(tester, 'Interest rate (annual)', '5');
      await typeInto(tester, 'Time (years)', '2');

      expect(find.text('₹ 1,000.00'), findsOneWidget);
      expect(find.text('₹ 11,000.00'), findsOneWidget);
    });
  });

  group('compound interest', () {
    testWidgets('10000 at 10% annual for 2 years gives 2100 interest', (
      tester,
    ) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'Compound interest');

      await typeInto(tester, 'Principal', '10000');
      await typeInto(tester, 'Interest rate (annual)', '10');
      await typeInto(tester, 'Time (years)', '2');

      expect(find.text('₹ 2,100.00'), findsOneWidget);
      expect(find.text('₹ 12,100.00'), findsOneWidget);
    });
  });

  group('GST', () {
    testWidgets('1000 at 18% exclusive, intra-state shows CGST/SGST', (
      tester,
    ) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'GST');

      await typeInto(tester, 'Amount', '1000');
      await typeInto(tester, 'GST rate', '18');

      expect(find.text('CGST'), findsOneWidget);
      expect(find.text('SGST'), findsOneWidget);
      // CGST and SGST rows, each 90.00 (half of the 180.00 GST amount).
      expect(find.text('₹ 90.00'), findsNWidgets(2));
      // The GST amount itself only appears once, as the chart's legend
      // value (no separate combined-GST row in intra-state mode).
      expect(find.text('₹ 180.00'), findsOneWidget);
      expect(find.text('₹ 1,180.00'), findsOneWidget);
    });

    testWidgets('switching to inter-state shows IGST instead', (tester) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'GST');

      await typeInto(tester, 'Amount', '1000');
      await typeInto(tester, 'GST rate', '18');
      await tester.tap(find.text('Inter-state (IGST)'));
      await tester.pumpAndSettle();

      expect(find.text('IGST'), findsOneWidget);
      expect(find.text('CGST'), findsNothing);
      // The IGST row and the chart's legend value are the same figure,
      // shown twice.
      expect(find.text('₹ 180.00'), findsNWidgets(2));
      expect(find.text('₹ 1,180.00'), findsOneWidget);
    });
  });

  group('discount', () {
    testWidgets('a 100% discount is allowed (a free item)', (tester) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'Discount');

      await typeInto(tester, 'Price', '1000');
      await typeInto(tester, 'Discount', '100');

      expect(find.text('₹ 0.00'), findsOneWidget);
    });

    testWidgets('a discount over 100% is rejected', (tester) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'Discount');

      await typeInto(tester, 'Price', '1000');
      await typeInto(tester, 'Discount', '101');

      expect(find.text('Enter at most 100'), findsOneWidget);
    });
  });

  group('tip', () {
    testWidgets('1000 bill, 10% tip, split 4 ways', (tester) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'Tip');

      await typeInto(tester, 'Bill amount', '1000');
      await typeInto(tester, 'Tip', '10');
      await typeInto(tester, 'Split between', '4');

      expect(find.text('₹ 275.00'), findsOneWidget);
      expect(find.text('₹ 100.00'), findsOneWidget);
      expect(find.text('₹ 1,100.00'), findsOneWidget);
    });
  });

  group('percentage', () {
    testWidgets('15% of 200 is 30', (tester) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'Percentage');

      await typeInto(tester, 'Percentage (%)', '15');
      await typeInto(tester, 'Of this amount', '200');

      expect(find.text('₹ 30.00'), findsOneWidget);
    });

    testWidgets('50 is what % of 200 is 25%', (tester) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'Percentage');

      await tester.tap(find.text('X is what % of Y'));
      await tester.pumpAndSettle();
      await typeInto(tester, 'This amount', '50');
      await typeInto(tester, 'Out of this total', '200');

      expect(find.text('25.00%'), findsOneWidget);
    });

    testWidgets('decreasing 200 by 15% gives 170', (tester) async {
      await pumpFinancial(tester);
      await selectTool(tester, 'Percentage');

      await tester.tap(find.text('Increase/decrease Y by X%'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decrease'));
      await tester.pumpAndSettle();
      await typeInto(tester, 'Percentage (%)', '15');
      await typeInto(tester, 'Starting amount', '200');

      expect(find.text('₹ 170.00'), findsOneWidget);
    });
  });
}
