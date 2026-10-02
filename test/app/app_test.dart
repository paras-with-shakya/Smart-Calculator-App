import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/shell/mode_picker.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_view.dart';
import 'package:smart_calculator/features/calculator/presentation/scientific_calculator_view.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_view.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';

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
    expect(find.byType(CalculatorView), findsOneWidget);
  });

  group('the navigation bar buttons contrast with the app', () {
    SystemUiOverlayStyle navigationBarStyle(WidgetTester tester) => tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byWidgetPredicate(
            (widget) =>
                widget is AnnotatedRegion<SystemUiOverlayStyle> &&
                widget.value.systemNavigationBarContrastEnforced == false,
          ),
        )
        .value;

    testWidgets('dark buttons over the light theme', (tester) async {
      await pumpApp(tester);

      final style = navigationBarStyle(tester);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      expect(style.systemNavigationBarColor, Colors.transparent);
    });

    testWidgets('light buttons over the dark theme', (tester) async {
      final preferences = await openPreferences();
      await PreferencesSettingsRepository(preferences)
          .setThemePreference(ThemePreference.dark);
      await pumpApp(tester, preferences: preferences);

      expect(
        navigationBarStyle(tester).systemNavigationBarIconBrightness,
        Brightness.light,
      );
    });
  });

  testWidgets('shows no "DEBUG" ribbon', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(find.byType(CheckedModeBanner), findsNothing);
  });

  testWidgets('Programmer mode shows the programmer calculator', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byType(ModePickerButton));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(l10n.modeProgrammer),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProgrammerView), findsOneWidget);
    expect(find.byType(CalculatorView), findsNothing);
    expect(find.byType(ScientificCalculatorView), findsNothing);
  });

  testWidgets('Scientific mode shows the scientific calculator', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byType(ModePickerButton));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(l10n.modeScientific),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ScientificCalculatorView), findsOneWidget);
  });
}
