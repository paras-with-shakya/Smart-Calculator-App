import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/converter/domain/conversion_tables.dart';
import 'package:smart_calculator/features/converter/domain/unit.dart';
import 'package:smart_calculator/features/converter/presentation/unit_names.dart';

import '../../../helpers/test_app.dart';

void main() {
  final units = <ConversionUnit>[
    for (final category in physicalCategories) ...category.units,
    ...currencyCategory(defaultCurrencyRatesPerUsd).units,
  ];

  test('every unit has a spoken name, not its symbol', () {
    expect(units, hasLength(34));
    for (final unit in units) {
      final spoken = spokenAmount(l10n, unit, 2, '2');
      expect(spoken, isNot('2 ${unit.symbol}'), reason: unit.id);
      expect(spoken, startsWith('2 '), reason: unit.id);
      expect(unitName(l10n, unit), isNotEmpty, reason: unit.id);
    }
  });

  test('the names are distinct, so search and screen readers can tell '
      'units apart', () {
    final names = {for (final unit in units) unitName(l10n, unit)};
    expect(names, hasLength(units.length));
  });

  group('singular and plural', () {
    ConversionUnit unit(String id) => units.firstWhere((u) => u.id == id);

    test('one of a unit is singular, even as a double', () {
      expect(spokenAmount(l10n, unit('m'), 1, '1'), '1 metre');
      expect(spokenAmount(l10n, unit('m'), 1.0, '1'), '1 metre');
      expect(spokenAmount(l10n, unit('foot'), 1, '1'), '1 foot');
    });

    test('anything else is plural', () {
      expect(spokenAmount(l10n, unit('m'), 0, '0'), '0 metres');
      expect(spokenAmount(l10n, unit('km'), 0.08, '0.08'), '0.08 kilometres');
      expect(spokenAmount(l10n, unit('ft2'), 12, '12'), '12 square feet');
      expect(
        spokenAmount(l10n, unit('celsius'), -44, '−44'),
        '−44 degrees Celsius',
      );
      expect(spokenAmount(l10n, unit('inr'), 83, '83'), '83 Indian rupees');
    });

    test('the name on its own is the plural', () {
      expect(unitName(l10n, unit('m')), 'metres');
      expect(unitName(l10n, unit('gallonUs')), 'US gallons');
    });
  });
}
