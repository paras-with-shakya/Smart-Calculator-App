import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/calculator/domain/scientific_keys.dart';

void main() {
  group('scientificKeyGroups', () {
    test('every group has at least one key', () {
      for (final group in scientificKeyGroups) {
        expect(group.keys, isNotEmpty, reason: '${group.name}');
      }
    });

    test('no CalculatorKey is a primary in more than one place', () {
      final primaries = [
        for (final group in scientificKeyGroups)
          for (final key in group.keys) key.primary,
      ];
      expect(primaries.toSet().length, primaries.length);
    });

    test('the seven keys with a real inverse map to it', () {
      const expected = {
        CalculatorKey.sin: CalculatorKey.asin,
        CalculatorKey.cos: CalculatorKey.acos,
        CalculatorKey.tan: CalculatorKey.atan,
        CalculatorKey.log: CalculatorKey.powerOfTen,
        CalculatorKey.ln: CalculatorKey.powerOfE,
        CalculatorKey.sqrt: CalculatorKey.square,
        CalculatorKey.cbrt: CalculatorKey.cube,
      };
      for (final MapEntry(key: primary, value: secondary) in expected.entries) {
        final key = _find(primary);
        expect(key.secondary, secondary, reason: '$primary');
        expect(key.hasSecondary, isTrue, reason: '$primary');
      }
    });

    test('keys with no engine-backed inverse are unaffected by 2nd', () {
      const unaffected = [
        CalculatorKey.sinh,
        CalculatorKey.cosh,
        CalculatorKey.tanh,
        CalculatorKey.abs,
        CalculatorKey.factorial,
        CalculatorKey.pi,
        CalculatorKey.euler,
        CalculatorKey.power,
      ];
      for (final primary in unaffected) {
        final key = _find(primary);
        expect(key.hasSecondary, isFalse, reason: '$primary');
        expect(key.keyFor(second: true), primary, reason: '$primary');
      }
    });

    test('keyFor(second: false) always returns the primary key', () {
      for (final group in scientificKeyGroups) {
        for (final key in group.keys) {
          expect(key.keyFor(second: false), key.primary);
        }
      }
    });
  });
}

ScientificKey _find(CalculatorKey primary) {
  for (final group in scientificKeyGroups) {
    for (final key in group.keys) {
      if (key.primary == primary) return key;
    }
  }
  throw StateError('No scientific key for $primary');
}
