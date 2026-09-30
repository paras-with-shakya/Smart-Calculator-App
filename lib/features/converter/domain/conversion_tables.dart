import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/converter/domain/unit.dart';

/// Length, base metre. `mile`/`yard`/`foot`/`inch` use the exact
/// international definitions (`1 inch = 0.0254 m`), so `1 mile = 5280 ft`
/// and `1 yard = 3 ft` hold exactly, not approximately.
const ConversionCategory lengthCategory = ConversionCategory(
  id: ConversionCategoryId.length,
  units: [
    ConversionUnit(id: 'm', symbol: 'm', scale: 1),
    ConversionUnit(id: 'km', symbol: 'km', scale: 1000),
    ConversionUnit(id: 'cm', symbol: 'cm', scale: 0.01),
    ConversionUnit(id: 'mm', symbol: 'mm', scale: 0.001),
    ConversionUnit(id: 'mile', symbol: 'mile', scale: 1609.344),
    ConversionUnit(id: 'yard', symbol: 'yard', scale: 0.9144),
    ConversionUnit(id: 'foot', symbol: 'foot', scale: 0.3048),
    ConversionUnit(id: 'inch', symbol: 'inch', scale: 0.0254),
  ],
);

/// Weight, base kilogram. `lb`/`oz` use the exact international avoirdupois
/// definition (`1 lb = 0.45359237 kg`), so `1 lb = 16 oz` holds exactly.
const ConversionCategory weightCategory = ConversionCategory(
  id: ConversionCategoryId.weight,
  units: [
    ConversionUnit(id: 'kg', symbol: 'kg', scale: 1),
    ConversionUnit(id: 'g', symbol: 'g', scale: 0.001),
    ConversionUnit(id: 'mg', symbol: 'mg', scale: 0.000001),
    ConversionUnit(id: 'lb', symbol: 'lb', scale: 0.45359237),
    ConversionUnit(id: 'oz', symbol: 'oz', scale: 0.028349523125),
  ],
);

/// Temperature, base Celsius. Genuinely affine, not a plain ratio:
/// Fahrenheit's `offset` is `-32 × 5/9`, in *base-unit* (Celsius) terms —
/// not the `+32` from the familiar `F = C×9/5+32` formula, which is the
/// opposite direction ([ConversionUnit.fromBase], not
/// [ConversionUnit.toBase]). Getting this backwards is the classic
/// temperature-conversion bug; the fixed points `0°C=32°F=273.15K`,
/// `100°C=212°F=373.15K` and `−40°C=−40°F` are what catch it (see
/// `conversion_tables_test.dart`).
const ConversionCategory temperatureCategory = ConversionCategory(
  id: ConversionCategoryId.temperature,
  allowsNegative: true,
  units: [
    ConversionUnit(id: 'celsius', symbol: '°C', scale: 1),
    ConversionUnit(
      id: 'fahrenheit',
      symbol: '°F',
      scale: 5 / 9,
      offset: -160 / 9,
    ),
    ConversionUnit(id: 'kelvin', symbol: 'K', scale: 1, offset: -273.15),
  ],
);

/// Area, base square metre. `ft2` is `foot`'s scale squared
/// (`0.3048² = 0.09290304`, exact), so `1 acre = 43560 ft²` holds exactly;
/// `hectare` is exactly `10000 m²`.
const ConversionCategory areaCategory = ConversionCategory(
  id: ConversionCategoryId.area,
  units: [
    ConversionUnit(id: 'm2', symbol: 'm²', scale: 1),
    ConversionUnit(id: 'km2', symbol: 'km²', scale: 1000000),
    ConversionUnit(id: 'ft2', symbol: 'ft²', scale: 0.09290304),
    ConversionUnit(id: 'acre', symbol: 'acre', scale: 4046.8564224),
    ConversionUnit(id: 'hectare', symbol: 'hectare', scale: 10000),
  ],
);

/// Volume, base litre. `gallonUs` is the US liquid gallon
/// (`3.785411784 L`, exactly `231 in³`) — the imperial gallon isn't
/// built (DEC-051). Named `gallonUs`, not `gallon`, so adding
/// `gallonImperial` later never means renaming a value that might already
/// be persisted as "last used unit".
const ConversionCategory volumeCategory = ConversionCategory(
  id: ConversionCategoryId.volume,
  units: [
    ConversionUnit(id: 'l', symbol: 'L', scale: 1),
    ConversionUnit(id: 'ml', symbol: 'mL', scale: 0.001),
    ConversionUnit(id: 'gallonUs', symbol: 'gallon (US)', scale: 3.785411784),
    ConversionUnit(id: 'm3', symbol: 'm³', scale: 1000),
  ],
);

/// Time, base second.
const ConversionCategory timeCategory = ConversionCategory(
  id: ConversionCategoryId.time,
  units: [
    ConversionUnit(id: 's', symbol: 's', scale: 1),
    ConversionUnit(id: 'min', symbol: 'min', scale: 60),
    ConversionUnit(id: 'h', symbol: 'h', scale: 3600),
    ConversionUnit(id: 'day', symbol: 'day', scale: 86400),
    ConversionUnit(id: 'week', symbol: 'week', scale: 604800),
  ],
);

/// The five physical categories with fixed, unchanging conversion
/// factors — every category except currency, whose rates are
/// user-editable (see [currencyCategory]).
const List<ConversionCategory> physicalCategories = [
  lengthCategory,
  weightCategory,
  temperatureCategory,
  areaCategory,
  volumeCategory,
  timeCategory,
];

/// The currency ids this app offers a rate for, base USD, in display
/// order. A short, curated list, not all of ISO 4217 (DEC-051): this is a
/// design for currency conversion with a user-typed rate, not a live feed.
const List<String> currencyIds = ['usd', 'inr', 'eur', 'gbp'];

/// The label shown for a currency id.
const Map<String, String> currencySymbols = {
  'usd': 'USD',
  'inr': 'INR',
  'eur': 'EUR',
  'gbp': 'GBP',
};

/// A starting rate ("how many of this currency equal 1 USD") shown the
/// first time the app runs, before the user edits it. These are round,
/// clearly-illustrative numbers, not real exchange rates — the UI labels
/// them as an example to edit, never as a live or accurate rate.
const Map<String, double> defaultCurrencyRatesPerUsd = {
  'usd': 1,
  'inr': 83,
  'eur': 0.9,
  'gbp': 0.8,
};

/// Builds the currency category from the current [ratesPerUsd] ("how many
/// of each currency equal 1 USD" — the natural way a person reads a rate,
/// "1 USD = 83 INR"). USD is always the fixed base (`scale = 1`); every
/// other currency's `scale` is `1 / rate`, so `toBase` (this currency to
/// USD) is dividing by the rate, matching the same `value * scale`
/// mechanism every other category uses. [ratesPerUsd] must have an entry
/// for every id in [currencyIds].
ConversionCategory currencyCategory(Map<String, double> ratesPerUsd) =>
    ConversionCategory(
      id: ConversionCategoryId.currency,
      units: [
        for (final id in currencyIds)
          ConversionUnit(
            id: id,
            symbol: currencySymbols[id]!,
            scale: id == 'usd' ? 1 : 1 / ratesPerUsd[id]!,
          ),
      ],
    );
