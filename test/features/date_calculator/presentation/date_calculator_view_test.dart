import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/core/formatting/date_format_provider.dart';
import 'package:smart_calculator/core/formatting/localized_date_format.dart';
import 'package:smart_calculator/core/time/clock_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_date_field.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/features/date_calculator/domain/date_offset.dart';
import 'package:smart_calculator/features/date_calculator/presentation/date_calculator_view.dart';

import '../../../helpers/test_app.dart';

const Size phone = Size(360, 800);
const Size phoneLandscape = Size(800, 360);

/// Late in the evening, so a bug that converted through UTC or another zone
/// would show the wrong day.
final DateTime fixedNow = DateTime(2026, 3, 8, 23, 30);

Finder dateFieldLabeled(String label) => find.byWidgetPredicate(
  (widget) => widget is AppDateField && widget.label == label,
);

Finder textFieldLabeled(String label) => find.byWidgetPredicate(
  (widget) => widget is AppTextField && widget.label == label,
);

void main() {
  setUp(useInMemoryPreferences);

  late LocalizedDateFormat format;

  Future<void> pumpDate(
    WidgetTester tester, {
    Size size = phone,
    DateTime? now,
  }) async {
    await pumpApp(
      tester,
      size: size,
      overrides: [clockProvider.overrideWithValue(() => now ?? fixedNow)],
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    format = container.read(dateFormatProvider);
    container.read(currentModeProvider.notifier).select(CalculatorMode.date);
    await tester.pumpAndSettle();
  }

  Future<void> selectTool(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  Future<void> pickDay(
    WidgetTester tester,
    String fieldLabel,
    String day,
  ) async {
    final field = dateFieldLabeled(fieldLabel);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(day).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> typeAmount(WidgetTester tester, String text) async {
    final field = textFieldLabeled(l10n.dateAmountLabel);
    await tester.ensureVisible(field);
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      text,
    );
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, String label) => tester
      .widget<TextField>(
        find.descendant(
          of: dateFieldLabeled(label),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  group('Date mode', () {
    testWidgets('shows the date calculator, not the placeholder', (
      tester,
    ) async {
      await pumpDate(tester);

      expect(find.byType(DateCalculatorView), findsOneWidget);
      expect(find.text(l10n.modeNotAvailableYet), findsNothing);
    });

    testWidgets('both dates start as today, even late in the evening', (
      tester,
    ) async {
      await pumpDate(tester);

      final today = format.short(DateTime.utc(2026, 3, 8));
      expect(fieldText(tester, l10n.dateFromLabel), today);
      expect(fieldText(tester, l10n.dateToLabel), today);
      expect(find.text(l10n.dateDays(0)), findsWidgets);
    });
  });

  group('difference', () {
    testWidgets('picking a later "To" date updates every figure', (
      tester,
    ) async {
      await pumpDate(tester);
      await pickDay(tester, l10n.dateToLabel, '22');

      expect(
        fieldText(tester, l10n.dateToLabel),
        format.short(DateTime.utc(2026, 3, 22)),
      );
      // 14 days: 2 weeks, 0 days.
      expect(find.text(l10n.dateDays(14)), findsNWidgets(2));
      expect(find.text(l10n.dateWeeks(2)), findsOneWidget);
      expect(find.text(l10n.dateMonths(0)), findsOneWidget);
    });

    testWidgets('an earlier "To" date gives the same gap', (tester) async {
      await pumpDate(tester);
      await pickDay(tester, l10n.dateToLabel, '1');

      expect(find.text(l10n.dateDays(7)), findsNWidgets(2));
      expect(find.text(l10n.dateWeeks(1)), findsOneWidget);
    });

    testWidgets('dismissing the picker leaves the date alone', (tester) async {
      await pumpDate(tester);
      final before = fieldText(tester, l10n.dateFromLabel);

      await tester.tap(dateFieldLabeled(l10n.dateFromLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(fieldText(tester, l10n.dateFromLabel), before);
    });
  });

  group('add or subtract', () {
    testWidgets('shows a placeholder until an amount is entered', (
      tester,
    ) async {
      await pumpDate(tester);
      await selectTool(tester, l10n.dateToolOffset);

      expect(find.text(l10n.dateOffsetPlaceholder), findsOneWidget);
    });

    testWidgets('adds 90 days', (tester) async {
      await pumpDate(tester);
      await selectTool(tester, l10n.dateToolOffset);
      await typeAmount(tester, '90');

      expect(find.text(format.long(DateTime.utc(2026, 6, 6))), findsOneWidget);
    });

    testWidgets('subtracts 6 months', (tester) async {
      await pumpDate(tester);
      await selectTool(tester, l10n.dateToolOffset);
      await tester.tap(find.text(l10n.dateDirectionSubtract));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.dateUnitMonths));
      await tester.pumpAndSettle();
      await typeAmount(tester, '6');

      expect(find.text(format.long(DateTime.utc(2025, 9, 8))), findsOneWidget);
    });

    testWidgets('adds years, keeping the day', (tester) async {
      await pumpDate(tester);
      await selectTool(tester, l10n.dateToolOffset);
      await tester.tap(find.text(l10n.dateUnitYears));
      await tester.pumpAndSettle();
      await typeAmount(tester, '2');

      expect(find.text(format.long(DateTime.utc(2028, 3, 8))), findsOneWidget);
    });

    testWidgets('an amount over the limit shows an error and no date', (
      tester,
    ) async {
      await pumpDate(tester);
      await selectTool(tester, l10n.dateToolOffset);
      await typeAmount(tester, '${maxDateAmount + 1}');

      expect(
        find.text(l10n.dateErrorAmountTooLarge(maxDateAmount)),
        findsOneWidget,
      );
      expect(find.text(l10n.dateOffsetPlaceholder), findsOneWidget);
    });

    testWidgets('a result outside years 1-9999 says so', (tester) async {
      await pumpDate(tester);
      await selectTool(tester, l10n.dateToolOffset);
      await tester.tap(find.text(l10n.dateUnitYears));
      await tester.pumpAndSettle();
      await typeAmount(tester, '$maxDateAmount');

      expect(find.text(l10n.dateErrorOutOfRange), findsOneWidget);
    });

    testWidgets('only digits can be typed in the amount', (tester) async {
      await pumpDate(tester);
      await selectTool(tester, l10n.dateToolOffset);
      await typeAmount(tester, '1a2.5-');

      final field = tester.widget<TextField>(
        find.descendant(
          of: textFieldLabeled(l10n.dateAmountLabel),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, '125');
    });
  });

  group('layout and accessibility', () {
    for (final (name, size) in [
      ('portrait', phone),
      ('landscape', phoneLandscape),
    ]) {
      for (final tool in [l10n.dateToolDifference, l10n.dateToolOffset]) {
        testWidgets('$name, $tool: no overflow, 48 dp targets', (tester) async {
          await pumpDate(tester, size: size);
          await selectTool(tester, tool);

          expect(tester.takeException(), isNull);
          for (final element in find.byType(AppCard).evaluate()) {
            final box = element.renderObject! as RenderBox;
            expect(box.size.height, greaterThanOrEqualTo(48));
          }
          for (final element in find.byType(TextField).evaluate()) {
            final box = element.renderObject! as RenderBox;
            expect(box.size.height, greaterThanOrEqualTo(48));
          }
        });
      }
    }

    testWidgets('200% text: nothing overflows and the full text is shown', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpDate(tester);
      await tester.tap(dateFieldLabeled(l10n.dateToLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await selectTool(tester, l10n.dateToolOffset);
      await typeAmount(tester, '90');

      expect(tester.takeException(), isNull);
      expect(find.text(format.long(DateTime.utc(2026, 6, 6))), findsOneWidget);
    });

    testWidgets('a date field is a labelled text field with its value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpDate(tester);

      final field = find.bySemanticsLabel(l10n.dateFromLabel);
      expect(field, findsOneWidget);
      final node = tester.getSemantics(field);
      expect(node.value, format.short(DateTime.utc(2026, 3, 8)));
      // A screen reader activating the field opens the picker.
      tester.semantics.tap(find.semantics.byLabel(l10n.dateFromLabel));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      handle.dispose();
    });
  });
}
