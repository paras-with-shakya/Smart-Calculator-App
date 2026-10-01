import 'dart:math' as math;

import 'package:smart_calculator/features/financial/domain/validation.dart';

/// How often interest compounds in a year.
enum CompoundingFrequency { annual, semiAnnual, quarterly, monthly }

/// The number of compounding periods per year, required (never hardcoded
/// to one frequency) and user-selectable in the UI.
extension CompoundingFrequencyPeriods on CompoundingFrequency {
  int get periodsPerYear => switch (this) {
    CompoundingFrequency.annual => 1,
    CompoundingFrequency.semiAnnual => 2,
    CompoundingFrequency.quarterly => 4,
    CompoundingFrequency.monthly => 12,
  };
}

/// The highest annual rate allowed — see `simple_interest.dart`'s
/// `maxSimpleInterestRatePercent` for the full reasoning.
const double maxCompoundInterestRatePercent = 1000;

/// The longest time allowed (100 years) — see
/// `maxSimpleInterestYears`'s reasoning.
const double maxCompoundInterestYears = 100;

/// Which compound-interest input fields are invalid, if any.
final class CompoundInterestErrors {
  const CompoundInterestErrors({this.principal, this.ratePercent, this.years});

  final FieldError? principal;
  final FieldError? ratePercent;
  final FieldError? years;

  bool get hasErrors =>
      principal != null || ratePercent != null || years != null;
}

/// Validates compound-interest inputs. [CompoundingFrequency] is a fixed
/// choice, never invalid, so it isn't part of this.
CompoundInterestErrors validateCompoundInterestInputs({
  required double principal,
  required double ratePercent,
  required double years,
}) => CompoundInterestErrors(
  principal: principal > 0 ? null : FieldError.mustBePositive,
  ratePercent: ratePercent < 0
      ? FieldError.mustBeNonNegative
      : ratePercent > maxCompoundInterestRatePercent
      ? FieldError.tooLarge
      : null,
  years: years <= 0
      ? FieldError.mustBePositive
      : years > maxCompoundInterestYears
      ? FieldError.tooLarge
      : null,
);

/// The computed total amount and interest earned.
final class CompoundInterestResult {
  const CompoundInterestResult({
    required this.totalAmount,
    required this.interest,
  });

  final double totalAmount;
  final double interest;
}

/// Computes compound interest: `A = P·(1+R/(100·n))^(n·T)`, `CI = A−P`,
/// where `n` is [frequency]'s periods per year. Returns null if the result
/// isn't finite — never formatted as literal "NaN"/"Infinity" text
/// (DEC-052).
CompoundInterestResult? calculateCompoundInterest({
  required double principal,
  required double ratePercent,
  required double years,
  required CompoundingFrequency frequency,
}) {
  final n = frequency.periodsPerYear;
  final totalAmount =
      principal * math.pow(1 + ratePercent / (100 * n), n * years).toDouble();
  final interest = totalAmount - principal;
  if (!totalAmount.isFinite || !interest.isFinite) return null;
  return CompoundInterestResult(totalAmount: totalAmount, interest: interest);
}
