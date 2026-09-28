import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_motion.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';

import '../../helpers/themed.dart';

void main() {
  Widget key({
    CalculatorButtonKind kind = CalculatorButtonKind.operator,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) => SizedBox.square(
    dimension: 80,
    child: CalculatorButton(
      kind: kind,
      label: '÷',
      semanticLabel: 'Divide',
      onPressed: onPressed,
      onLongPress: onLongPress,
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
}
