import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/converter/domain/unit.dart';

void main() {
  group('ConversionUnit', () {
    test('a purely proportional unit (offset 0) scales both ways', () {
      const km = ConversionUnit(id: 'km', symbol: 'km', scale: 1000);

      expect(km.toBase(2), 2000);
      expect(km.fromBase(2000), 2);
    });

    test('an affine unit (non-zero offset) applies it after scaling', () {
      const fahrenheit = ConversionUnit(
        id: 'f',
        symbol: '°F',
        scale: 5 / 9,
        offset: -160 / 9,
      );

      // 32°F is 0°C.
      expect(fahrenheit.toBase(32), closeTo(0, 1e-9));
      expect(fahrenheit.fromBase(0), closeTo(32, 1e-9));
    });
  });

  group('ConversionCategory', () {
    const testCategory = ConversionCategory(
      id: ConversionCategoryId.length,
      units: [
        ConversionUnit(id: 'base', symbol: 'b', scale: 1),
        ConversionUnit(id: 'double', symbol: 'd', scale: 2),
      ],
    );

    test('unit() finds a unit by id', () {
      expect(testCategory.unit('double').scale, 2);
    });

    test('unit() throws for an id this category does not have', () {
      expect(() => testCategory.unit('triple'), throwsArgumentError);
    });

    test('convert() goes through the base unit', () {
      // 3 of the "double" unit is 6 base units, which is 3 of "double"
      // again (converting to itself) and also 6 of "base".
      expect(testCategory.convert(3, from: 'double', to: 'base'), 6);
      expect(testCategory.convert(6, from: 'base', to: 'double'), 3);
      expect(testCategory.convert(3, from: 'double', to: 'double'), 3);
    });
  });
}
