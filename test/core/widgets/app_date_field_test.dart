import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/formatting/localized_date_format.dart';
import 'package:smart_calculator/core/widgets/app_date_field.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    for (final locale in ['en_US', 'en_GB', 'en_IN']) {
      await initializeLocalizedDates(locale);
    }
  });

  final format = LocalizedDateFormat('en_US');

  Widget host({
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    DateTime? first,
    DateTime? last,
  }) => MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AppDateField(
        label: 'Start date',
        value: value,
        format: format.short,
        pickerHelpText: 'Select date',
        firstDate: first ?? DateTime.utc(1900),
        lastDate: last ?? DateTime.utc(2200, 12, 31),
        onChanged: onChanged,
      ),
    ),
  );

  testWidgets('shows the formatted value under its label', (tester) async {
    await tester.pumpWidget(
      host(value: DateTime.utc(2026, 3, 8), onChanged: (_) {}),
    );

    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('Sun, Mar 8, 2026'), findsOneWidget);
  });

  testWidgets('picking a day reports a UTC calendar date', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      host(value: DateTime.utc(2026, 3, 8), onChanged: (d) => picked = d),
    );

    await tester.tap(find.byType(AppDateField));
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsOneWidget);
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(picked, DateTime.utc(2026, 3, 20));
    expect(picked!.isUtc, isTrue);
  });

  testWidgets('cancelling reports nothing', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(value: DateTime.utc(2026, 3, 8), onChanged: (_) => calls++),
    );

    await tester.tap(find.byType(AppDateField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('a value outside the allowed range does not crash the picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        value: DateTime.utc(1500, 6, 1),
        first: DateTime.utc(1900),
        onChanged: (_) {},
      ),
    );

    await tester.tap(find.byType(AppDateField));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('follows a new value from its parent', (tester) async {
    await tester.pumpWidget(
      host(value: DateTime.utc(2026, 3, 8), onChanged: (_) {}),
    );
    await tester.pumpWidget(
      host(value: DateTime.utc(2027, 1, 2), onChanged: (_) {}),
    );

    expect(find.text('Sat, Jan 2, 2027'), findsOneWidget);
  });

  group('LocalizedDateFormat', () {
    final date = DateTime.utc(2026, 3, 8);

    test('orders day and month the way the region does', () {
      expect(LocalizedDateFormat('en_US').short(date), 'Sun, Mar 8, 2026');
      expect(LocalizedDateFormat('en_GB').short(date), 'Sun, 8 Mar 2026');
      expect(LocalizedDateFormat('en_IN').short(date), 'Sun, 8 Mar, 2026');
    });

    test('long form spells out weekday and month', () {
      expect(LocalizedDateFormat('en_US').long(date), 'Sunday, March 8, 2026');
    });

    test('an unknown locale falls back to English', () {
      expect(LocalizedDateFormat('xx_YY').short(date), 'Sun, Mar 8, 2026');
    });

    test('does not move a date across a day boundary', () {
      final lastMinute = DateTime.utc(2026, 3, 8, 23, 59);
      expect(LocalizedDateFormat('en_US').short(lastMinute), contains('Mar 8'));
    });
  });

  group('ResultRow', () {
    Widget row({required bool wrap}) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: ResultRow(
            label: 'Date',
            value: 'Wednesday, September 29, 2027 and more words',
            wrapValue: wrap,
          ),
        ),
      ),
    );

    testWidgets('wrapValue lets a long value take more lines', (tester) async {
      await tester.pumpWidget(row(wrap: true));
      final wrapped = tester.getSize(find.byType(ResultRow)).height;
      await tester.pumpWidget(row(wrap: false));
      final clipped = tester.getSize(find.byType(ResultRow)).height;

      expect(wrapped, greaterThan(clipped));
    });
  });
}
