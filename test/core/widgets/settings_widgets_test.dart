import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/widgets/app_switch_tile.dart';
import 'package:smart_calculator/core/widgets/setting_row.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  group('AppSwitchTile', () {
    testWidgets('shows its title and hint, and the switch state', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          AppSwitchTile(
            title: 'Haptics',
            hint: 'A short tick.',
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Haptics'), findsOneWidget);
      expect(find.text('A short tick.'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('tapping anywhere on the row reports the opposite value', (
      tester,
    ) async {
      bool? reported;
      await tester.pumpWidget(
        host(
          AppSwitchTile(
            title: 'Haptics',
            value: false,
            onChanged: (value) => reported = value,
          ),
        ),
      );

      await tester.tap(find.text('Haptics'));

      expect(reported, isTrue);
    });

    testWidgets('without a hint there is just the title', (tester) async {
      await tester.pumpWidget(
        host(AppSwitchTile(title: 'Haptics', value: true, onChanged: (_) {})),
      );

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('a null onChanged disables it', (tester) async {
      await tester.pumpWidget(
        host(
          const AppSwitchTile(title: 'Haptics', value: true, onChanged: null),
        ),
      );

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
    });

    testWidgets('is one control for a screen reader, with the state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          AppSwitchTile(
            title: 'Haptics',
            hint: 'A short tick.',
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(SwitchListTile));
      expect(node.label, contains('Haptics'));
      expect(node.label, contains('A short tick.'));
      expect(
        node,
        isSemantics(hasToggledState: true, isToggled: true, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets('is at least 48 dp tall', (tester) async {
      await tester.pumpWidget(
        host(AppSwitchTile(title: 'Haptics', value: true, onChanged: (_) {})),
      );

      expect(
        tester.getSize(find.byType(SwitchListTile)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('SettingRow', () {
    testWidgets('shows the label, the hint and the control, in that order', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SettingRow(
            label: 'Decimal places',
            hint: 'Rounds the fraction.',
            child: SizedBox(key: ValueKey('control'), height: 48),
          ),
        ),
      );

      final label = tester.getTopLeft(find.text('Decimal places')).dy;
      final hint = tester.getTopLeft(find.text('Rounds the fraction.')).dy;
      final control = tester
          .getTopLeft(find.byKey(const ValueKey('control')))
          .dy;
      expect(label, lessThan(hint));
      expect(hint, lessThan(control));
    });

    testWidgets('the hint is optional', (tester) async {
      await tester.pumpWidget(
        host(const SettingRow(label: 'Theme', child: SizedBox(height: 48))),
      );

      expect(find.text('Theme'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('the control takes the full width of the row', (tester) async {
      await tester.pumpWidget(
        host(
          const SettingRow(
            label: 'Theme',
            child: SizedBox(key: ValueKey('control'), height: 48),
          ),
        ),
      );

      final width = tester.getSize(find.byKey(const ValueKey('control'))).width;
      final screen = tester.getSize(find.byType(Scaffold)).width;
      expect(width, screen - 32);
    });
  });
}
