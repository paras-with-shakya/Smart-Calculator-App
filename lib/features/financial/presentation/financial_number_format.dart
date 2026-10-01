import 'package:smart_calculator/core/formatting/localized_number_format.dart';

/// Formats a money amount to 2 decimal places, with the rupee sign, in the
/// region's number format. The one rounding boundary for every financial
/// tool: every domain calculation stays full `double` precision, and only
/// this display text is ever rounded (DEC-052).
String formatMoney(LocalizedNumberFormat format, double value) =>
    '₹ ${format.formatCanonical(value.toStringAsFixed(2))}';

/// Formats a percentage value to 2 decimal places. The `%` sign itself is
/// the caller's label, not part of this text.
String formatPercent(LocalizedNumberFormat format, double value) =>
    format.formatCanonical(value.toStringAsFixed(2));
