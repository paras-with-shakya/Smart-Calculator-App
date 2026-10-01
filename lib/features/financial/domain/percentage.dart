import 'package:smart_calculator/features/financial/domain/validation.dart';

/// Which of the three percentage operations is selected. The roadmap lists
/// "discount, tip and percentage" as one grouped bullet (unlike EMI/GST's
/// own dedicated bullets) — read as "percentage" being the lighter,
/// generalized sibling of discount/tip's specific cases, so this stays one
/// flexible tool with these three common operations rather than several
/// full separate calculators (DEC-052).
enum PercentageOperation { percentOf, whatPercent, changeBy }

/// For [PercentageOperation.changeBy], which direction.
enum PercentageDirection { increase, decrease }

/// The highest "decrease by" percentage allowed — mirrors `discount.dart`'s
/// `maxDiscountPercent` exactly: can't decrease more than the whole.
const double maxDecreasePercent = 100;

/// Which percentage input fields are invalid, if any.
///
/// Shared across all three operations: [x] is the percentage value (or,
/// for [PercentageOperation.whatPercent], the part), [y] is the base (or,
/// for [PercentageOperation.whatPercent], the whole).
final class PercentageErrors {
  const PercentageErrors({this.x, this.y});

  final FieldError? x;
  final FieldError? y;

  bool get hasErrors => x != null || y != null;
}

/// Validates "X% of Y" inputs.
PercentageErrors validatePercentOfInputs({
  required double x,
  required double y,
}) => PercentageErrors(
  x: x < 0 ? FieldError.mustBeNonNegative : null,
  y: y > 0 ? null : FieldError.mustBePositive,
);

/// `Y·X/100` — what X% of Y is.
double calculatePercentOf({required double x, required double y}) =>
    y * x / 100;

/// Validates "X is what % of Y" inputs. [y] must be positive to avoid
/// dividing by zero.
PercentageErrors validateWhatPercentInputs({
  required double x,
  required double y,
}) => PercentageErrors(
  x: x < 0 ? FieldError.mustBeNonNegative : null,
  y: y > 0 ? null : FieldError.mustBePositive,
);

/// `X/Y·100` — what percentage X is of Y.
double calculateWhatPercent({required double x, required double y}) =>
    x / y * 100;

/// Validates "increase/decrease Y by X%" inputs. A "decrease" [x] is
/// additionally capped at [maxDecreasePercent] (can't decrease more than
/// the whole); "increase" has no such ceiling.
PercentageErrors validateChangeByInputs({
  required double x,
  required double y,
  required PercentageDirection direction,
}) => PercentageErrors(
  x: x < 0
      ? FieldError.mustBeNonNegative
      : direction == PercentageDirection.decrease && x > maxDecreasePercent
      ? FieldError.tooLarge
      : null,
  y: y > 0 ? null : FieldError.mustBePositive,
);

/// `Y·(1±X/100)` — Y increased or decreased by X%.
double calculateChangeBy({
  required double x,
  required double y,
  required PercentageDirection direction,
}) => direction == PercentageDirection.increase
    ? y * (1 + x / 100)
    : y * (1 - x / 100);
