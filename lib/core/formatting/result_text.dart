import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';

/// [value] as a calculator result is shown: in the device region's number
/// format, with up to 12 significant digits, and, if [decimalPlaces] is set,
/// the fraction rounded to that many places first (a whole number is never
/// changed).
///
/// Every place that shows a result of Basic or Scientific mode uses this, so
/// the "decimal places" setting applies everywhere at once.
String formatResult(
  LocalizedNumberFormat format,
  CalcValue value, {
  int? decimalPlaces,
}) =>
    format.formatCanonical(value.toDecimalString(decimalPlaces: decimalPlaces));
