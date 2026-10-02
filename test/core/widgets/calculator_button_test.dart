import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_motion.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';

import '../../helpers/themed.dart';

void main() {
  Widget key({
    CalculatorButtonKind kind = CalculatorButtonKind.operator,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    bool selected = false,
  }) => SizedBox.square(
    dimension: 80,
    child: CalculatorButton(
      kind: kind,
      label: '÷',
      semanticLabel: 'Divide',
      onPressed: onPressed,
      onLongPress: onLongPress,
      selected: selected,
    ),
  );

  testWidgets('screen readers hear the semantic label, not the symbol', (
    tester,
  ) async {
    await pumpThemed(tester, key(onPressed: () {}));

    expect(
      tester.getSemantics(find.byType(CalculatorButton)),
      isSemantics(label: 'Divide', isButton: true, isEnabled: true),
    );
    expect(find.bySemanticsLabel('÷'), findsNothing);
  });

  testWidgets('each kind uses its tone from the palette', (tester) async {
    const c = AppColors.light;
    final tones = {
      CalculatorButtonKind.digit: (c.digitKey, c.onDigitKey),
      CalculatorButtonKind.operator: (c.operatorKey, c.onOperatorKey),
      CalculatorButtonKind.function: (c.functionKey, c.onFunctionKey),
      CalculatorButtonKind.equals: (c.equalsKey, c.onEqualsKey),
    };
    for (final MapEntry(key: kind, value: (fill, label)) in tones.entries) {
      await pumpThemed(tester, key(kind: kind, onPressed: () {}));

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(CalculatorButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, fill, reason: '$kind fill');
      expect(
        tester.widget<Text>(find.text('÷')).style!.color,
        label,
        reason: '$kind label',
      );
    }
  });

  testWidgets('selected is announced and toned with the accent, not the kind, '
      'in every palette', (tester) async {
    Color materialColorOf(WidgetTester tester) => tester
        .widget<Material>(
          find.descendant(
            of: find.byType(CalculatorButton),
            matching: find.byType(Material),
          ),
        )
        .color!;

    for (final theme in [
      AppTheme.light,
      AppTheme.dark,
      AppTheme.highContrastLight,
      AppTheme.highContrastDark,
    ]) {
      await pumpThemed(
        tester,
        key(kind: CalculatorButtonKind.function, onPressed: () {}),
        theme: theme,
      );
      final resting = materialColorOf(tester);

      await pumpThemed(
        tester,
        key(
          kind: CalculatorButtonKind.function,
          onPressed: () {},
          selected: true,
        ),
        theme: theme,
      );
      expect(
        materialColorOf(tester),
        isNot(resting),
        reason: '$theme: selected must not match the resting function tone',
      );
    }

    await pumpThemed(
      tester,
      key(kind: CalculatorButtonKind.function, onPressed: () {}),
    );
    expect(
      tester.getSemantics(find.byType(CalculatorButton)),
      isSemantics(label: 'Divide', isButton: true, isEnabled: true),
    );

    await pumpThemed(
      tester,
      key(
        kind: CalculatorButtonKind.function,
        onPressed: () {},
        selected: true,
      ),
    );
    expect(
      tester.getSemantics(find.byType(CalculatorButton)),
      isSemantics(
        label: 'Divide',
        isButton: true,
        isEnabled: true,
        isSelected: true,
      ),
    );
  });

  testWidgets('memory keys have no fill and a muted label', (tester) async {
    await pumpThemed(
      tester,
      key(kind: CalculatorButtonKind.memory, onPressed: () {}),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(CalculatorButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, Colors.transparent);
    expect(
      tester.widget<Text>(find.text('÷')).style!.color,
      AppColors.light.textMuted,
    );
  });

  testWidgets('in high contrast, keys are outlined but memory keys are not', (
    tester,
  ) async {
    BorderSide sideOf(CalculatorButtonKind kind) {
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(CalculatorButton),
          matching: find.byType(Material),
        ),
      );
      return (material.shape! as RoundedSuperellipseBorder).side;
    }

    await pumpThemed(
      tester,
      key(kind: CalculatorButtonKind.digit, onPressed: () {}),
      theme: AppTheme.highContrastLight,
    );
    expect(sideOf(CalculatorButtonKind.digit), isNot(BorderSide.none));

    await pumpThemed(
      tester,
      key(kind: CalculatorButtonKind.memory, onPressed: () {}),
      theme: AppTheme.highContrastLight,
    );
    expect(sideOf(CalculatorButtonKind.memory), BorderSide.none);
  });

  testWidgets('tap and long press call their callbacks', (tester) async {
    var taps = 0;
    var longPresses = 0;
    await pumpThemed(
      tester,
      key(onPressed: () => taps++, onLongPress: () => longPresses++),
    );

    await tester.tap(find.byType(CalculatorButton));
    await tester.longPress(find.byType(CalculatorButton));

    expect(taps, 1);
    expect(longPresses, 1);
  });

  testWidgets('a disabled key ignores taps and is announced as disabled', (
    tester,
  ) async {
    await pumpThemed(tester, key());

    expect(
      tester.getSemantics(find.byType(CalculatorButton)),
      isSemantics(label: 'Divide', isEnabled: false),
    );
  });

  testWidgets('is never smaller than the 48 dp touch target', (tester) async {
    await pumpThemed(
      tester,
      const CalculatorButton(
        kind: CalculatorButtonKind.digit,
        label: '7',
        semanticLabel: '7',
        onPressed: null,
      ),
    );

    final size = tester.getSize(find.byType(CalculatorButton));
    expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
  });

  testWidgets('its label shrinks instead of overflowing at 200% text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpThemed(
      tester,
      SizedBox.square(
        dimension: kMinInteractiveDimension,
        child: CalculatorButton(
          kind: CalculatorButtonKind.function,
          label: 'AC',
          semanticLabel: 'All clear',
          onPressed: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('press feedback is instant when reduced motion is on', (
    tester,
  ) async {
    Duration pressDuration() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration;

    await pumpThemed(tester, key(onPressed: () {}));
    expect(pressDuration(), AppMotion.short);

    await pumpThemed(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: key(onPressed: () {}),
      ),
    );
    expect(pressDuration(), Duration.zero);
  });

  testWidgets('screen readers hear what a long press does', (tester) async {
    Widget backspace({VoidCallback? onLongPress}) => SizedBox.square(
      dimension: 80,
      child: CalculatorButton(
        kind: CalculatorButtonKind.function,
        icon: Icons.backspace_outlined,
        semanticLabel: 'Backspace',
        onPressed: () {},
        onLongPress: onLongPress,
        longPressHint: 'clear everything',
      ),
    );

    await pumpThemed(tester, backspace(onLongPress: () {}));
    expect(
      tester
          .getSemantics(find.byType(CalculatorButton))
          .hintOverrides
          ?.onLongPressHint,
      'clear everything',
    );

    // No long press, so nothing to hint at.
    await pumpThemed(tester, backspace());
    expect(
      tester
          .getSemantics(find.byType(CalculatorButton))
          .hintOverrides
          ?.onLongPressHint,
      isNull,
    );
  });
}
