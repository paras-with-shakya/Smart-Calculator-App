import 'dart:math' as math;

import 'package:smart_calculator/features/financial/domain/validation.dart';

/// The unit a tenure was typed in.
enum TenureUnit { years, months }

/// The longest tenure allowed (50 years) — not a numeric-stability limit
/// (`double` handles far larger `n` fine), a UX sanity bound: no realistic
/// retail loan runs longer, so anything past this is almost certainly a
/// units typo (DEC-052).
const int maxEmiTenureMonths = 600;

/// The highest annual rate allowed. The brief only requires
/// non-negativity, but an uncapped rate is a real bug path, not just excess
/// permissiveness: at a rule-legal rate this large combined with a long
/// tenure, `(1+r)ⁿ` overflows `double` to `Infinity` and the EMI formula
/// evaluates to `NaN`. `1000%` is already far beyond any real rate and
/// stays comfortably finite at every tenure below (DEC-052).
const double maxEmiRatePercent = 1000;

/// Converts a tenure typed as [value] in [unit] to a whole number of
/// months, rounding to the nearest month for a fractional year (e.g. `2.33`
/// years → `27.96` → **28** months) — the EMI formula's `n` must be a whole
/// number of months.
int tenureMonthsFrom({required double value, required TenureUnit unit}) =>
    unit == TenureUnit.months ? value.round() : (value * 12).round();

/// Which EMI input fields are invalid, if any.
final class EmiErrors {
  const EmiErrors({this.principal, this.ratePercent, this.tenureMonths});

  final FieldError? principal;
  final FieldError? ratePercent;
  final FieldError? tenureMonths;

  bool get hasErrors =>
      principal != null || ratePercent != null || tenureMonths != null;
}

/// Validates EMI inputs. [tenureMonths] is the already-converted whole
/// number of months (see [tenureMonthsFrom]).
EmiErrors validateEmiInputs({
  required double principal,
  required double ratePercent,
  required int tenureMonths,
}) => EmiErrors(
  principal: principal > 0 ? null : FieldError.mustBePositive,
  ratePercent: ratePercent < 0
      ? FieldError.mustBeNonNegative
      : ratePercent > maxEmiRatePercent
      ? FieldError.tooLarge
      : null,
  tenureMonths: tenureMonths <= 0
      ? FieldError.mustBePositive
      : tenureMonths > maxEmiTenureMonths
      ? FieldError.tooLarge
      : null,
);

/// The computed EMI, total payment and total interest.
final class EmiResult {
  const EmiResult({
    required this.monthlyEmi,
    required this.totalPayment,
    required this.totalInterest,
  });

  final double monthlyEmi;
  final double totalPayment;
  final double totalInterest;
}

/// Computes the monthly EMI for [principal] at [ratePercent] annual
/// interest over [tenureMonths] months: `EMI = P·r·(1+r)ⁿ/((1+r)ⁿ−1)`,
/// where `r` is the monthly rate. Zero-interest loans (`ratePercent == 0`)
/// are special-cased to `EMI = P/n`, since the general formula's
/// denominator would otherwise be exactly zero.
///
/// Returns null if the result isn't finite — only reachable, even with
/// [maxEmiRatePercent], at extreme rule-legal input combinations; never
/// formatted as literal "NaN"/"Infinity" text (DEC-052).
EmiResult? calculateEmi({
  required double principal,
  required double ratePercent,
  required int tenureMonths,
}) {
  final monthlyRate = ratePercent / 12 / 100;
  final double emi;
  if (monthlyRate == 0) {
    emi = principal / tenureMonths;
  } else {
    final growth = math.pow(1 + monthlyRate, tenureMonths).toDouble();
    emi = principal * monthlyRate * growth / (growth - 1);
  }
  final totalPayment = emi * tenureMonths;
  final totalInterest = totalPayment - principal;
  if (!emi.isFinite || !totalPayment.isFinite || !totalInterest.isFinite) {
    return null;
  }
  return EmiResult(
    monthlyEmi: emi,
    totalPayment: totalPayment,
    totalInterest: totalInterest,
  );
}
