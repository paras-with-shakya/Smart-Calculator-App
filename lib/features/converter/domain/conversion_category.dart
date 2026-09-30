import 'package:smart_calculator/features/converter/domain/unit.dart';

/// The conversion categories, in the order they're shown.
enum ConversionCategoryId {
  /// m, km, cm, mm, mile, yard, foot, inch.
  length,

  /// kg, g, mg, lb, oz.
  weight,

  /// °C, °F, K.
  temperature,

  /// m², km², ft², acre, hectare.
  area,

  /// L, mL, gallon (US), m³.
  volume,

  /// s, min, h, day, week.
  time,

  /// A short, user-editable list of currencies (DEC-051): no live rates,
  /// no network — the exchange rate is typed in and saved locally.
  currency,
}

/// One category: its units and whether a negative amount makes sense.
///
/// [units] must be non-empty and have no repeated [ConversionUnit.id].
/// Exactly one unit is the category's base unit — the one whose
/// [ConversionUnit.scale] is `1` and [ConversionUnit.offset] is `0` —
/// every other unit converts through it.
final class ConversionCategory {
  /// Creates a category. [allowsNegative] is true only for temperature:
  /// every other category's amounts (a length, a weight, a duration, …)
  /// can't sensibly be negative.
  const ConversionCategory({
    required this.id,
    required this.units,
    this.allowsNegative = false,
  });

  /// Which category this is.
  final ConversionCategoryId id;

  /// The units in this category, in display order.
  final List<ConversionUnit> units;

  /// Whether a negative amount makes sense in this category.
  final bool allowsNegative;

  /// The unit with this [id]. Throws if none matches — every unit id this
  /// app uses (typed literals, or persisted "last used unit" strings) is
  /// checked against this category's actual [units] before being trusted.
  ConversionUnit unit(String id) => units.firstWhere(
    (unit) => unit.id == id,
    orElse: () => throw ArgumentError('No unit "$id" in $this'),
  );

  /// Converts [value] from unit [from] to unit [to] (both unit ids).
  double convert(double value, {required String from, required String to}) =>
      unit(to).fromBase(unit(from).toBase(value));

  @override
  String toString() => 'ConversionCategory($id)';
}
