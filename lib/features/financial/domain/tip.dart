import 'package:smart_calculator/features/financial/domain/validation.dart';

/// The highest tip allowed. Unlike discount, there's no mathematical
/// ceiling here — a tip isn't subtracted from anything that could go
/// negative — but a 100%+ tip is far more likely a misplaced decimal than
/// genuine intent, so it's still rejected as a fat-finger guard.
const double maxTipPercent = 100;

/// Which tip input fields are invalid, if any.
final class TipErrors {
  const TipErrors({this.bill, this.tipPercent, this.splitCount});

  final FieldError? bill;
  final FieldError? tipPercent;
  final FieldError? splitCount;

  bool get hasErrors =>
      bill != null || tipPercent != null || splitCount != null;
}

/// Validates tip inputs.
TipErrors validateTipInputs({
  required double bill,
  required double tipPercent,
  required int splitCount,
}) => TipErrors(
  bill: bill > 0 ? null : FieldError.mustBePositive,
  tipPercent: tipPercent < 0
      ? FieldError.mustBeNonNegative
      : tipPercent > maxTipPercent
      ? FieldError.tooLarge
      : null,
  splitCount: splitCount >= 1 ? null : FieldError.mustBePositiveInteger,
);

/// The computed tip amount, total and per-person share.
final class TipResult {
  const TipResult({
    required this.tipAmount,
    required this.total,
    required this.perPerson,
  });

  final double tipAmount;
  final double total;

  /// `total / splitCount` — a `splitCount` of 1 means "no splitting," so
  /// this always equals [total] in that case. Per-person rounding is not
  /// redistributed to force an exact sum across all people (DEC-052) —
  /// that's an expected rounding artifact, not a bug.
  final double perPerson;
}

/// Computes a tip: `tipAmount = bill·tip%/100`, `total = bill+tipAmount`,
/// `perPerson = total/splitCount`.
TipResult? calculateTip({
  required double bill,
  required double tipPercent,
  required int splitCount,
}) {
  final tipAmount = bill * tipPercent / 100;
  final total = bill + tipAmount;
  final perPerson = total / splitCount;
  if (!tipAmount.isFinite || !total.isFinite || !perPerson.isFinite) {
    return null;
  }
  return TipResult(tipAmount: tipAmount, total: total, perPerson: perPerson);
}
