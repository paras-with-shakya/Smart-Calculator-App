import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_header.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/core/widgets/section_header.dart';

import '../../helpers/themed.dart';

void main() {
  Material materialOf(WidgetTester tester) => tester.widget<Material>(
    find.descendant(of: find.byType(AppCard), matching: find.byType(Material)),
  );

  group('AppCard', () {
    testWidgets('a tappable card calls onTap and is a button', (tester) async {
      var taps = 0;
      await pumpThemed(
        tester,
        AppCard(onTap: () => taps++, child: const Text('Basic')),
      );

      await tester.tap(find.text('Basic'));

      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(AppCard)),
        isSemantics(isButton: true),
      );
    });

    testWidgets('selected: accent tint, matching text colour, and announced', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        AppCard(selected: true, onTap: () {}, child: const Text('Basic')),
      );

      expect(materialOf(tester).color, AppColors.light.primaryContainer);
      expect(
        DefaultTextStyle.of(tester.element(find.text('Basic'))).style.color,
        AppColors.light.onPrimaryContainer,
      );
      expect(
        tester.getSemantics(find.byType(AppCard)),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('has no outline normally, and a visible one in high contrast', (
      tester,
    ) async {
      BorderSide sideOf() => (materialOf(tester).shape! as OutlinedBorder).side;

      await pumpThemed(tester, const AppCard(child: Text('Total')));
      expect(sideOf().style, BorderStyle.none);

      await pumpThemed(
        tester,
        const AppCard(child: Text('Total')),
        theme: AppTheme.highContrastLight,
      );
      // MaterialApp animates from the previous theme to the new one.
      await tester.pumpAndSettle();
      expect(sideOf().color, AppColors.highContrastLight.contrastOutline);
    });
  });

  testWidgets('SectionHeader is a heading for screen readers', (tester) async {
    await pumpThemed(tester, const SectionHeader('Appearance'));

    expect(
      tester.getSemantics(find.text('Appearance')),
      isSemantics(label: 'Appearance', isHeader: true),
    );
  });

  testWidgets('AppIconButton is labelled by its tooltip', (tester) async {
    await pumpThemed(
      tester,
      AppIconButton(icon: Icons.history, tooltip: 'History', onPressed: () {}),
    );

    expect(find.byTooltip('History'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('AppHeader shows its title and actions, and a back button on '
      'a pushed page', (tester) async {
    await pumpThemed(tester, const SizedBox.shrink());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppHeader(
            title: const Text('Settings'),
            actions: [
              AppIconButton(
                icon: Icons.help_outline,
                tooltip: 'Help',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byTooltip('Help'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
