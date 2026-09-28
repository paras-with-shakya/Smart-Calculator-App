import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// WCAG AA minimums; the high-contrast palettes must meet AAA for text.
const double _textAA = 4.5;
const double _textAAA = 7;
const double _nonText = 3;

typedef _Pair = (String name, Color foreground, Color background);

List<_Pair> _textPairs(AppColors c) => [
  for (final (name, bg) in [
    ('background', c.background),
    ('surface', c.surface),
    ('card', c.card),
    ('surfaceMuted', c.surfaceMuted),
  ]) ...[
    ('textPrimary on $name', c.textPrimary, bg),
    ('textMuted on $name', c.textMuted, bg),
  ],
  for (final (name, bg) in [
    ('background', c.background),
    ('surface', c.surface),
    ('card', c.card),
  ]) ...[
    ('primary on $name', c.primary, bg),
    ('success on $name', c.success, bg),
    ('warning on $name', c.warning, bg),
    ('error on $name', c.error, bg),
  ],
  ('onPrimary on primary', c.onPrimary, c.primary),
  (
    'onPrimaryContainer on primaryContainer',
    c.onPrimaryContainer,
    c.primaryContainer,
  ),
  ('onSecondary on secondary', c.onSecondary, c.secondary),
  ('onError on error', c.onError, c.error),
  ('onDigitKey on digitKey', c.onDigitKey, c.digitKey),
  ('onOperatorKey on operatorKey', c.onOperatorKey, c.operatorKey),
  ('onFunctionKey on functionKey', c.onFunctionKey, c.functionKey),
  ('onEqualsKey on equalsKey', c.onEqualsKey, c.equalsKey),
];

List<_Pair> _nonTextPairs(AppColors c) => [
  ('outline on background', c.outline, c.background),
  ('outline on surface', c.outline, c.surface),
  ('secondary on background', c.secondary, c.background),
];

/// Pairs below [minimum], formatted for a readable failure message.
List<String> _failures(List<_Pair> pairs, double minimum) => [
  for (final (name, fg, bg) in pairs)
    if (_contrast(fg, bg) < minimum)
      '$name: ${_contrast(fg, bg).toStringAsFixed(2)} < $minimum',
];

void main() {
  test('the contrast formula matches WCAG reference values', () {
    expect(_contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(
      _contrast(const Color(0xFF777777), Colors.white),
      closeTo(4.48, 0.01),
    );
  });

  for (final (name, palette) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$name palette', () {
      test('text meets WCAG AA (4.5:1)', () {
        expect(_failures(_textPairs(palette), _textAA), isEmpty);
      });

      test('outlines and icons meet 3:1', () {
        expect(_failures(_nonTextPairs(palette), _nonText), isEmpty);
      });
    });
  }

  for (final (name, palette) in [
    ('high-contrast light', AppColors.highContrastLight),
    ('high-contrast dark', AppColors.highContrastDark),
  ]) {
    group('$name palette', () {
      test('text meets WCAG AAA (7:1)', () {
        expect(_failures(_textPairs(palette), _textAAA), isEmpty);
      });

      test('outlines, dividers and key edges meet 4.5:1', () {
        expect(
          _failures([
            ..._nonTextPairs(palette),
            ('divider on background', palette.divider, palette.background),
            (
              'contrastOutline on background',
              palette.contrastOutline,
              palette.background,
            ),
          ], _textAA),
          isEmpty,
        );
      });
    });
  }
}
