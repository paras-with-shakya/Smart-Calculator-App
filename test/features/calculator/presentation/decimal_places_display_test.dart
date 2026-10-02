import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/core/formatting/result_text.dart';
import 'package:smart_calculator/core/widgets/display_text.dart';
import 'package:smart_calculator/features/calculator/domain/expression_buffer.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_display_formatter.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';

import '../../../helpers/test_app.dart';

CalcValue evaluate(String expression) =>
    (const CalcEngine().evaluate(expression) as CalcSuccess).value;

Finder displayed(String text) => find.byWidgetPredicate(
  (widget) => widget is DisplayText && widget.text == text,
);

void main() {
  setUp(useInMemoryPreferences);

  final us = LocalizedNumberFormat('en_US');
  final india = LocalizedNumberFormat('en_IN');

  group('formatResult', () {
    test('rounds the fraction, keeps the region format', () {
      final third = evaluate('1÷3');
      expect(formatResult(us, third), '0.333333333333');
      expect(formatResult(us, third, decimalPlaces: 2), '0.33');
      expect(formatResult(us, third, decimalPlaces: 6), '0.333333');
    });

    test('a whole number is never touched, only grouped', () {
      final big = evaluate('1234567.891');
      expect(formatResult(india, big, decimalPlaces: 2), '12,34,567.89');
      expect(formatResult(india, big, decimalPlaces: 0), '12,34,568');
      expect(
        formatResult(us, evaluate('987654+123456'), decimalPlaces: 2),
        '1,111,110',
      );
    });

    test('a negative value keeps the typographic minus', () {
      expect(formatResult(us, evaluate('−2÷3'), decimalPlaces: 2), '−0.67');
    });
  });

  group('CalculatorDisplayFormatter', () {
    final rounding = CalculatorDisplayFormatter(us, l10n, decimalPlaces: 2);
    final third = evaluate('1÷3');

    test('a result is rounded', () {
      expect(rounding.value(third), '0.33');
    });

    test('a value written inside an expression is not', () {
      final buffer = ExpressionBuffer.of([
        ValueUnit(third),
        const SymbolUnit('+'),
        const SymbolUnit('1'),
      ]);
      expect(
        rounding.expression(buffer).text,
        '0.333333333333+${CalculatorDisplayFormatter.lineBreakOpportunity}1',
      );
    });

    test('a spoken expression keeps the full value too', () {
      final buffer = ExpressionBuffer.of([
        ValueUnit(third),
        const SymbolUnit('+'),
        const SymbolUnit('1'),
      ]);
      expect(rounding.spokenExpression(buffer), contains('0.333333333333'));
    });

    test('without decimalPlaces nothing changes', () {
      expect(
        CalculatorDisplayFormatter(us, l10n).value(third),
        '0.333333333333',
      );
    });
  });

  group('on screen', () {
    late ProviderContainer container;

    Future<void> pumpCalculator(WidgetTester tester) async {
      await pumpApp(tester);
      container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
    }

    Future<void> press(WidgetTester tester, String keys) async {
      for (final key in keys.split('')) {
        await tester.tap(find.text(key));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('the live preview and the result follow the setting', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await container
          .read(appSettingsProvider.notifier)
          .setDecimalPlaces(DecimalPlaces.two);
      await press(tester, '1÷3');

      expect(displayed('0.33'), findsOneWidget); // the preview
      await press(tester, '=');
      expect(displayed('0.33'), findsWidgets);
      expect(displayed('0.333333333333'), findsNothing);
    });

    testWidgets('a change in Settings applies to the result already shown', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await press(tester, '1÷3=');
      expect(displayed('0.333333333333'), findsWidgets);

      await container
          .read(appSettingsProvider.notifier)
          .setDecimalPlaces(DecimalPlaces.four);
      await tester.pumpAndSettle();

      expect(displayed('0.3333'), findsWidgets);
      expect(displayed('0.333333333333'), findsNothing);
    });

    testWidgets('the saved exact result is untouched by rounding', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await container
          .read(appSettingsProvider.notifier)
          .setDecimalPlaces(DecimalPlaces.two);
      await press(tester, '1÷3=×3=');

      // 1/3 is exact inside the calculation, so ×3 gives exactly 1.
      expect(displayed('1'), findsWidgets);
    });

    testWidgets('a whole-number result is the same at any setting', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await container
          .read(appSettingsProvider.notifier)
          .setDecimalPlaces(DecimalPlaces.two);
      await press(tester, '987654+123456=');

      expect(displayed('1,111,110'), findsWidgets);
    });
  });

  group('history', () {
    testWidgets('shows the result rounded, and searches what is shown', (
      tester,
    ) async {
      await pumpApp(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      await container
          .read(appSettingsProvider.notifier)
          .setDecimalPlaces(DecimalPlaces.two);
      for (final key in '2÷3'.split('')) {
        await tester.tap(find.text(key));
        await tester.pump();
      }
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.historyTitle));
      await tester.pumpAndSettle();

      expect(find.text('0.67'), findsOneWidget);
      expect(find.text('0.666666666667'), findsNothing);

      await tester.enterText(find.byType(TextField), '0.67');
      await tester.pumpAndSettle();
      expect(find.text('0.67'), findsWidgets);
      expect(find.text(l10n.historySearchEmptyMessage), findsNothing);
    });
  });
}
