import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';

import '../../helpers/real_fonts.dart';
import '../../helpers/themed.dart';

void main() {
  // The layout depends on how wide the labels are, so measure them in the
  // real font (the default test font draws every glyph as a wide square).
  setUpAll(loadRealFonts);

  const shortOptions = [
    AppChoice(value: 'system', label: 'System', icon: Icons.brightness_auto),
    AppChoice(value: 'light', label: 'Light', icon: Icons.light_mode),
    AppChoice(value: 'dark', label: 'Dark', icon: Icons.dark_mode),
  ];

  /// Pumps the group in a column [width] wide: the settings page's content
  /// width on a 360 dp phone is 328 dp.
  Future<List<String>> pumpGroup(
    WidgetTester tester, {
    List<AppChoice<String>> options = shortOptions,
    double width = 328,
  }) async {
    final chosen = <String>[];
    await pumpThemed(
      tester,
      SizedBox(
        width: width,
        child: StatefulBuilder(
          builder: (context, setState) => AppChoiceGroup<String>(
            options: options,
            selected: chosen.isEmpty ? options.first.value : chosen.last,
            onChanged: (value) => setState(() => chosen.add(value)),
          ),
        ),
      ),
    );
    return chosen;
  }

  testWidgets('shows a segmented button when every label fits', (tester) async {
    final chosen = await pumpGroup(tester);

    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    expect(find.byType(RadioListTile<String>), findsNothing);
    await tester.tap(find.text('Dark'));
    expect(chosen, ['dark']);
  });

  testWidgets('switches to a radio list at 200% text, without overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final chosen = await pumpGroup(tester);

    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.byType(RadioListTile<String>), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Light'));
    await tester.pump();
    expect(chosen, ['light']);
    expect(
      tester.getSemantics(find.byType(RadioListTile<String>).at(1)),
      isSemantics(isChecked: true, isInMutuallyExclusiveGroup: true),
    );
  });

  testWidgets('switches to a radio list when a label is too long for its '
      'segment', (tester) async {
    await pumpGroup(
      tester,
      options: const [
        AppChoice(value: 'a', label: 'Follow the device setting'),
        AppChoice(value: 'b', label: 'Light'),
        AppChoice(value: 'c', label: 'Dark'),
      ],
    );

    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.byType(RadioListTile<String>), findsNWidgets(3));
  });

  testWidgets('the radio list works on a plain coloured background', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ColoredBox(
          color: const Color(0xFFF2EFEA),
          child: Center(
            child: SizedBox(
              width: 328,
              child: AppChoiceGroup<String>(
                options: shortOptions,
                selected: 'light',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(RadioListTile<String>), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
