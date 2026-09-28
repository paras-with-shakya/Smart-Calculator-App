import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/navigation/app_route.dart';
import 'package:smart_calculator/app/shell/app_shell.dart';
import 'package:smart_calculator/features/history/presentation/history_page.dart';
import 'package:smart_calculator/features/settings/presentation/settings_page.dart';

import '../../helpers/test_app.dart';

void main() {
  setUp(useInMemoryPreferences);

  String? routeNameOf(WidgetTester tester, Type page) =>
      ModalRoute.of(tester.element(find.byType(page)))?.settings.name;

  testWidgets('the settings action pushes the settings page; back returns', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip(l10n.settingsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(routeNameOf(tester, SettingsPage), const SettingsRoute().name);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('the history action pushes the history page; back returns', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip(l10n.historyTitle));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryPage), findsOneWidget);
    expect(routeNameOf(tester, HistoryPage), const HistoryRoute().name);
    expect(find.text(l10n.historyNotAvailableYet), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HistoryPage), findsNothing);
  });
}
