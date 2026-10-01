import 'package:smart_calculator/features/financial/domain/validation.dart';

/// The highest annual rate allowed — not required by the brief (which only
/// asks for non-negativity), but an uncapped rate is a real bug path: an
/// extreme rule-legal rate can overflow a `double` to `Infinity`/`NaN`
/// (see `emi.dart`'s `maxEmiRatePercent` for the full reasoning, which
/// applies identically here even though this formula has no exponent).
const double maxSimpleInterestRatePercent = 1000;

/// The longest time allowed (100 years, comfortably a lifetime) — a UX
/// sanity bound, not a numeric one; also catches a units typo (e.g. months
/// typed into a years field).
const double maxSimpleInterestYears = 100;

/// Which simple-interest input fields are invalid, if any.
final class SimpleInterestErrors {
  const SimpleInterestErrors({this.principal, this.ratePercent, this.years});

  final FieldError? principal;
  final FieldError? ratePercent;
  final FieldError? years;

  bool get hasErrors =>
      principal != null || ratePercent != null || years != null;
}

/// Validates simple-interest inputs.
SimpleInterestErrors validateSimpleInterestInputs({
  required double principal,
  required double ratePercent,
  required double years,
}) => SimpleInterestErrors(
  principal: principal > 0 ? null : FieldError.mustBePositive,
  ratePercent: ratePercent < 0
      ? FieldError.mustBeNonNegative
      : ratePercent > maxSimpleInterestRatePercent
      ? FieldError.tooLarge
      : null,
  years: years <= 0
      ? FieldError.mustBePositive
      : years > maxSimpleInterestYears
      ? FieldError.tooLarge
      : null,
);

/// The computed interest and total amount.
final class SimpleInterestResult {
  const SimpleInterestResult({
    required this.interest,
    required this.totalAmount,
  });

  final double interest;
  final double totalAmount;
}

/// Computes simple interest: `SI = P·R·T/100` (R annual %, T years,
/// fractional years allowed). Returns null if the result isn't finite —
/// never formatted as literal "NaN"/"Infinity" text (DEC-052).
SimpleInterestResult? calculateSimpleInterest({
  required double principal,
  required double ratePercent,
  required double years,
}) {
  final interest = principal * ratePercent * years / 100;
  final totalAmount = principal + interest;
  if (!interest.isFinite || !totalAmount.isFinite) return null;
  return SimpleInterestResult(interest: interest, totalAmount: totalAmount);
}
