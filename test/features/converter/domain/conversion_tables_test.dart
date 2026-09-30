import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/converter/domain/conversion_tables.dart';

/// A combined absolute+relative tolerance: pure relative tolerance breaks
/// at `expected == 0` (exactly one of the values these tests check), so
/// every comparison uses `max(absEps, relEps * |expected|)`.
Matcher approximately(double expected) {
  const absEps = 1e-9;
  const relEps = 1e-9;
  final eps = absEps > relEps * expected.abs()
      ? absEps
      : relEps * expected.abs();
  return closeTo(expected, eps);
}

void main() {
  group('temperature: fixed points (catches the classic offset-sign bug)', () {
    final celsius = temperatureCategory.unit('celsius');
    final fahrenheit = temperatureCategory.unit('fahrenheit');
    final kelvin = temperatureCategory.unit('kelvin');

    test('0°C = 32°F = 273.15K', () {
      expect(fahrenheit.fromBase(celsius.toBase(0)), approximately(32));
      expect(kelvin.fromBase(celsius.toBase(0)), approximately(273.15));
    });

    test('100°C = 212°F = 373.15K', () {
      expect(fahrenheit.fromBase(celsius.toBase(100)), approximately(212));
      expect(kelvin.fromBase(celsius.toBase(100)), approximately(373.15));
    });

    test('−40°C = −40°F', () {
      expect(fahrenheit.fromBase(celsius.toBase(-40)), approximately(-40));
    });

    test('the other direction: 32°F, 273.15K are 0°C', () {
      expect(celsius.fromBase(fahrenheit.toBase(32)), approximately(0));
      expect(celsius.fromBase(kelvin.toBase(273.15)), approximately(0));
    });
  });

  group('exact integer cross-checks (independent of round-tripping)', () {
    test('1 mile = 5280 ft = 1760 yd', () {
      expect(
        lengthCategory.convert(1, from: 'mile', to: 'foot'),
        approximately(5280),
      );
      expect(
        lengthCategory.convert(1, from: 'mile', to: 'yard'),
        approximately(1760),
      );
    });

    test('1 lb = 16 oz', () {
      expect(
        weightCategory.convert(1, from: 'lb', to: 'oz'),
        approximately(16),
      );
    });

    test('1 acre = 43560 ft²', () {
      expect(
        areaCategory.convert(1, from: 'acre', to: 'ft2'),
        approximately(43560),
      );
    });

    test('1 hectare = 10000 m²', () {
      expect(
        areaCategory.convert(1, from: 'hectare', to: 'm2'),
        approximately(10000),
      );
    });

    test('1 US gallon = 231 in³ (via the exact 3.785411784 L constant)', () {
      // in³ isn't a unit in this app, so this checks litres directly:
      // 1 US gallon is defined as exactly 3.785411784 L.
      expect(volumeCategory.convert(1, from: 'gallonUs', to: 'l'), 3.785411784);
    });

    test('1 hour = 3600 s, 1 day = 24 h, 1 week = 7 day', () {
      expect(timeCategory.convert(1, from: 'h', to: 's'), 3600);
      expect(timeCategory.convert(1, from: 'day', to: 'h'), 24);
      expect(timeCategory.convert(1, from: 'week', to: 'day'), 7);
    });
  });

  group('round-trip: every unit, to its base and back', () {
    const values = [0.0, 1.0, -1.0, 0.0001, 123456.789, -273.15];

    for (final category in physicalCategories) {
      for (final unit in category.units) {
        for (final value in values) {
          if (value < 0 && !category.allowsNegative) continue;
          test('${category.id.name}/${unit.id}: $value round-trips', () {
            expect(unit.fromBase(unit.toBase(value)), approximately(value));
          });
        }
      }
    }
  });

  group('pairwise round-trip: every unit to every other unit and back', () {
    const values = [1.0, 100.0, 0.5];

    for (final category in physicalCategories) {
      for (final a in category.units) {
        for (final b in category.units) {
          if (a.id == b.id) continue;
          for (final value in values) {
            test(
              '${category.id.name}: $value ${a.id} -> ${b.id} -> ${a.id}',
              () {
                final converted = category.convert(value, from: a.id, to: b.id);
                final back = category.convert(converted, from: b.id, to: a.id);
                expect(back, approximately(value));
              },
            );
          }
        }
      }
    }
  });

  group('currencyCategory', () {
    test('USD is always the fixed base', () {
      final category = currencyCategory({
        'usd': 1,
        'inr': 83,
        'eur': 0.9,
        'gbp': 0.8,
      });

      expect(category.unit('usd').scale, 1);
      expect(category.unit('usd').offset, 0);
    });

    test('a rate of "83 INR per USD" converts 1 USD to 83 INR', () {
      final category = currencyCategory({
        'usd': 1,
        'inr': 83,
        'eur': 0.9,
        'gbp': 0.8,
      });

      expect(category.convert(1, from: 'usd', to: 'inr'), approximately(83));
      expect(category.convert(83, from: 'inr', to: 'usd'), approximately(1));
    });

    test('changing the rate changes the conversion', () {
      final before = currencyCategory({
        'usd': 1,
        'inr': 83,
        'eur': 0.9,
        'gbp': 0.8,
      });
      final after = currencyCategory({
        'usd': 1,
        'inr': 90,
        'eur': 0.9,
        'gbp': 0.8,
      });

      expect(before.convert(1, from: 'usd', to: 'inr'), approximately(83));
      expect(after.convert(1, from: 'usd', to: 'inr'), approximately(90));
    });

    test('every currency id has a default starting rate', () {
      for (final id in currencyIds) {
        expect(defaultCurrencyRatesPerUsd.containsKey(id), isTrue, reason: id);
        expect(currencySymbols.containsKey(id), isTrue, reason: id);
      }
    });
  });
}
