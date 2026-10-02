import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';

/// Expects every [CalculatorButton] on screen to be at least
/// [kMinInteractiveDimension] (48 dp) in both directions, skipping the ones
/// [except] picks out.
void expectTouchTargets(
  WidgetTester tester, {
  bool Function(CalculatorButton)? except,
}) {
  for (final element in find.byType(CalculatorButton).evaluate()) {
    final widget = element.widget as CalculatorButton;
    if (except != null && except(widget)) continue;
    final size = (element.renderObject! as RenderBox).size;
    expect(
      size.height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
      reason: widget.semanticLabel,
    );
    expect(
      size.width,
      greaterThanOrEqualTo(kMinInteractiveDimension),
      reason: widget.semanticLabel,
    );
  }
}
