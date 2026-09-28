import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/status_views.dart';

import '../../helpers/themed.dart';

void main() {
  testWidgets('EmptyState shows its icon, title, message and action', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(
      tester,
      EmptyState(
        icon: Icons.history,
        title: 'No calculations yet',
        message: 'Results appear here.',
        action: AppButton(label: 'Start', onPressed: () => taps++),
      ),
    );

    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.text('No calculations yet'), findsOneWidget);
    expect(find.text('Results appear here.'), findsOneWidget);
    await tester.tap(find.text('Start'));
    expect(taps, 1);
  });

  testWidgets('ErrorState shows the message and a retry', (tester) async {
    var retries = 0;
    await pumpThemed(
      tester,
      ErrorState(
        message: 'Something went wrong.',
        action: AppButton(label: 'Try again', onPressed: () => retries++),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Something went wrong.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('LoadingState shows progress and is announced as it appears', (
    tester,
  ) async {
    await pumpThemed(tester, const LoadingState(message: 'Loading history…'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LoadingState)),
      isSemantics(isLiveRegion: true),
    );
  });

  testWidgets('status views scroll instead of overflowing at 200% text in a '
      'short space', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpThemed(
      tester,
      SizedBox(
        width: 320,
        height: 200,
        child: EmptyState(
          icon: Icons.history,
          title: 'No calculations yet',
          message: 'Results you calculate appear here, newest first.',
          action: AppButton(label: 'Start calculating', onPressed: () {}),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
