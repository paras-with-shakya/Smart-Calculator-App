import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/widgets/share_of_whole_bar.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget bar) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: bar),
    ),
  );

  testWidgets('renders both legend labels and values', (tester) async {
    await pump(
      tester,
      const ShareOfWholeBar(
        baseLabel: 'Principal',
        baseValue: 100000,
        baseValueText: '₹1,00,000.00',
        addedLabel: 'Interest',
        addedValue: 50000,
        addedValueText: '₹50,000.00',
      ),
    );

    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('₹1,00,000.00'), findsOneWidget);
    expect(find.text('Interest'), findsOneWidget);
    expect(find.text('₹50,000.00'), findsOneWidget);
  });

  testWidgets(
    'a near-zero segment still renders (does not throw or disappear)',
    (tester) async {
      await pump(
        tester,
        const ShareOfWholeBar(
          baseLabel: 'Base',
          baseValue: 100000,
          baseValueText: '₹1,00,000.00',
          addedLabel: 'Added',
          addedValue: 0.01,
          addedValueText: '₹0.01',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('₹0.01'), findsOneWidget);
    },
  );

  testWidgets('the legend shows the true value, not a rounded flex weight', (
    tester,
  ) async {
    await pump(
      tester,
      const ShareOfWholeBar(
        baseLabel: 'Base',
        baseValue: 999999,
        baseValueText: '₹9,99,999.00',
        addedLabel: 'Added',
        addedValue: 1,
        addedValueText: '₹1.00',
      ),
    );

    expect(find.text('₹1.00'), findsOneWidget);
  });

  test('a non-positive total trips the documented precondition', () {
    expect(
      () => ShareOfWholeBar(
        baseLabel: 'Base',
        baseValue: 0,
        baseValueText: '0',
        addedLabel: 'Added',
        addedValue: 0,
        addedValueText: '0',
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
