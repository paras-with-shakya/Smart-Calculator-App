/// A unit within a conversion category, converting to/from the category's
/// base unit by one affine transform: `toBase(v) = v * scale + offset`.
///
/// Every category in this app — even temperature, which isn't a plain
/// ratio — fits this one mechanism: a purely proportional unit (km, lb, …)
/// just has `offset = 0`.
final class ConversionUnit {
  /// Creates a unit. [id] is a stable identifier, never renamed once
  /// shipped — it is what gets persisted as "last used unit". [symbol] is
  /// the short label shown on screen ("km", "°F").
  const ConversionUnit({
    required this.id,
    required this.symbol,
    required this.scale,
    this.offset = 0,
  });

  /// A stable identifier for persistence, distinct from [symbol] so the
  /// displayed label can change without invalidating saved state.
  final String id;

  /// The short label shown on screen.
  final String symbol;

  /// How many of the category's base unit one of this unit is worth,
  /// before [offset] is added.
  final double scale;

  /// A fixed amount added after scaling, in base-unit terms. Zero for
  /// every purely proportional unit; non-zero only for temperature.
  final double offset;

  /// Converts [value], in this unit, to the category's base unit.
  double toBase(double value) => value * scale + offset;

  /// Converts [base] (in the category's base unit) to this unit.
  double fromBase(double base) => (base - offset) / scale;

  @override
  String toString() => 'ConversionUnit($id)';
}
