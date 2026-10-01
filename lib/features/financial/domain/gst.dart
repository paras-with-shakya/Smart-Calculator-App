import 'package:smart_calculator/features/financial/domain/validation.dart';

/// Whether the entered amount already includes GST.
enum GstMode { exclusive, inclusive }

/// The highest rate allowed — a currency/jurisdiction-agnostic outer bound
/// (no real consumption tax exceeds 100%), not a hardcode of India's
/// specific 5/12/18/28 slabs, which stay free-entry presets in the UI.
const double maxGstRatePercent = 100;

/// Which GST input fields are invalid, if any.
final class GstErrors {
  const GstErrors({this.amount, this.ratePercent});

  final FieldError? amount;
  final FieldError? ratePercent;

  bool get hasErrors => amount != null || ratePercent != null;
}

/// Validates GST inputs.
GstErrors validateGstInputs({
  required double amount,
  required double ratePercent,
}) => GstErrors(
  amount: amount > 0 ? null : FieldError.mustBePositive,
  ratePercent: ratePercent < 0
      ? FieldError.mustBeNonNegative
      : ratePercent > maxGstRatePercent
      ? FieldError.tooLarge
      : null,
);

/// The computed base amount, GST amount and total.
final class GstResult {
  const GstResult({
    required this.baseAmount,
    required this.gstAmount,
    required this.totalAmount,
  });

  final double baseAmount;
  final double gstAmount;
  final double totalAmount;
}

/// Computes GST for [amount] at [ratePercent]. In [GstMode.exclusive],
/// [amount] is the pre-tax base and GST is added on top:
/// `gst = amount·rate/100`, `total = amount+gst`. In [GstMode.inclusive],
/// [amount] is the tax-inclusive total and GST is extracted back out of it:
/// `base = amount/(1+rate/100)`, `gst = amount−base`.
///
/// Returns null if the result isn't finite — never formatted as literal
/// "NaN"/"Infinity" text (DEC-052).
GstResult? calculateGst({
  required double amount,
  required double ratePercent,
  required GstMode mode,
}) {
  final double baseAmount;
  final double gstAmount;
  switch (mode) {
    case GstMode.exclusive:
      baseAmount = amount;
      gstAmount = amount * ratePercent / 100;
    case GstMode.inclusive:
      baseAmount = amount / (1 + ratePercent / 100);
      gstAmount = amount - baseAmount;
  }
  final totalAmount = baseAmount + gstAmount;
  if (!baseAmount.isFinite || !gstAmount.isFinite || !totalAmount.isFinite) {
    return null;
  }
  return GstResult(
    baseAmount: baseAmount,
    gstAmount: gstAmount,
    totalAmount: totalAmount,
  );
}

/// The CGST/SGST split for an intra-state supply: each is exactly half of
/// [gstAmount] — a presentation choice over the same total, never a
/// different total from the inter-state IGST case (which instead shows the
/// whole [gstAmount] as one figure). DEC-052 records this convention
/// explicitly since it's easy to get backwards.
({double cgst, double sgst}) splitIntraState(double gstAmount) =>
    (cgst: gstAmount / 2, sgst: gstAmount / 2);
