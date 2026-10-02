import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: card),
    ),
  );

  /// The semantics node that carries [text] in its label.
  SemanticsNode nodeWith(WidgetTester tester, String text) =>
      tester.getSemantics(find.textContaining(text).first);

  group('ResultCard', () {
    testWidgets('reads as one item with every label and value', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(
        tester,
        const ResultCard(
          children: [
            ResultRow(label: 'Monthly EMI', value: '₹8,791.59'),
            ResultRow(label: 'Total interest', value: '₹5,499.06'),
          ],
        ),
      );

      final node = nodeWith(tester, 'Monthly EMI');
      expect(node.label, contains('Monthly EMI'));
      expect(node.label, contains('₹8,791.59'));
      expect(node.label, contains('Total interest'));
      expect(node.label, contains('₹5,499.06'));
      expect(node, isSemantics(isLiveRegion: false));
      handle.dispose();
    });

    testWidgets('a live card is one live node whose label follows the value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Widget card(String days) => ResultCard(
        liveRegion: true,
        children: [ResultRow(label: 'Total days', value: days)],
      );

      await pumpCard(tester, card('3 days'));
      final before = nodeWith(tester, 'Total days');
      expect(before, isSemantics(isLiveRegion: true));
      expect(before.label, contains('3 days'));

      await pumpCard(tester, card('89 days'));
      final after = nodeWith(tester, 'Total days');
      // Android announces a live region only when its own label changes.
      expect(after.id, before.id);
      expect(after, isSemantics(isLiveRegion: true));
      expect(after.label, contains('89 days'));
      handle.dispose();
    });
  });

  testWidgets('a live ResultPlaceholder is one live node', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCard(
      tester,
      const ResultPlaceholder(message: 'Out of range', liveRegion: true),
    );

    final node = nodeWith(tester, 'Out of range');
    expect(node, isSemantics(isLiveRegion: true));
    expect(node.label, 'Out of range');
    handle.dispose();
  });

  group('ResultRow', () {
    Future<void> pumpRow(WidgetTester tester, {required double textScale}) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: const Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 600,
                    child: ResultRow(
                      label: 'Weeks and days',
                      value: '12 weeks, 5 days',
                      wrapValue: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    bool cutShort(WidgetTester tester, String text) =>
        tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;

    testWidgets('puts the value beside the label when both fit', (
      tester,
    ) async {
      await pumpRow(tester, textScale: 1);

      final label = tester.getRect(find.text('Weeks and days'));
      final value = tester.getRect(find.text('12 weeks, 5 days'));
      expect(value.left, greaterThan(label.right));
      expect(value.center.dy, closeTo(label.center.dy, 1));
    });

    testWidgets('puts the value under the label at 200% text, cutting '
        'neither short', (tester) async {
      await pumpRow(tester, textScale: 2);

      final label = tester.getRect(find.text('Weeks and days'));
      final value = tester.getRect(find.text('12 weeks, 5 days'));
      expect(value.top, greaterThanOrEqualTo(label.bottom));
      expect(cutShort(tester, 'Weeks and days'), isFalse);
      expect(cutShort(tester, '12 weeks, 5 days'), isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
