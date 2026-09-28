import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(useInMemoryPreferences);

  testWidgets('starts in Basic mode, following the system theme', (
    tester,
  ) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(tester.widget<Title>(find.byType(Title)).title, l10n.appTitle);
    expect(find.text(l10n.modeBasic), findsOneWidget);
    expect(find.text(l10n.modeNotAvailableYet), findsOneWidget);
  });
}
