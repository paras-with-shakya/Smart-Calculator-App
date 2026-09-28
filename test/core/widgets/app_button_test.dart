import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';

import '../../helpers/themed.dart';

void main() {
  Color fillOf(WidgetTester tester) => tester
      .widget<Material>(
        find
            .descendant(
              of: find.byType(AppButton),
              matching: find.byType(Material),
            )
            .first,
      )
      .color!;

  testWidgets('each variant uses its colour role', (tester) async {
    const colors = AppColors.light;
    final expected = {
      AppButtonVariant.primary: colors.primary,
      AppButtonVariant.secondary: colors.surfaceMuted,
      AppButtonVariant.destructive: colors.error,
    };
    for (final MapEntry(key: variant, value: fill) in expected.entries) {
      await pumpThemed(
        tester,
        AppButton(label: 'Go', variant: variant, onPressed: () {}),
      );
      expect(fillOf(tester), fill, reason: '$variant');
    }

    await pumpThemed(
      tester,
      AppButton(label: 'Go', variant: AppButtonVariant.text, onPressed: () {}),
    );
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('calls onPressed when tapped; a null callback disables it', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(tester, AppButton(label: 'Save', onPressed: () => taps++));
    await tester.tap(find.text('Save'));
    expect(taps, 1);

    await pumpThemed(tester, const AppButton(label: 'Save', onPressed: null));
    expect(
      tester.getSemantics(find.byType(AppButton)),
      isSemantics(label: 'Save', isButton: true, isEnabled: false),
    );
  });

  testWidgets('loading shows progress, ignores taps, and keeps its size and '
      'its label for screen readers', (tester) async {
    var taps = 0;
    await pumpThemed(tester, AppButton(label: 'Save', onPressed: () => taps++));
    final idleSize = tester.getSize(find.byType(AppButton));

    await pumpThemed(
      tester,
      AppButton(label: 'Save', isLoading: true, onPressed: () => taps++),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(AppButton)), idleSize);
    expect(
      tester.getSemantics(find.byType(AppButton)),
      isSemantics(label: 'Save', isEnabled: false),
    );
    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('is at least 48 dp tall, and shows its icons', (tester) async {
    await pumpThemed(
      tester,
      AppButton(
        label: 'Basic',
        icon: Icons.calculate_outlined,
        trailingIcon: Icons.arrow_drop_down,
        onPressed: () {},
      ),
    );

    expect(
      tester.getSize(find.byType(AppButton)).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
  });

  testWidgets('expand fills the available width', (tester) async {
    await pumpThemed(
      tester,
      SizedBox(
        width: 300,
        child: AppButton(label: 'Done', expand: true, onPressed: () {}),
      ),
    );

    expect(tester.getSize(find.byType(AppButton)).width, 300);
  });
}
