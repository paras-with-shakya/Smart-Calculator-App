import 'package:smart_calculator/features/financial/domain/validation.dart';

/// The highest discount allowed. A discount over 100% would make the final
/// price negative, so this is rejected outright, never clamped.
const double maxDiscountPercent = 100;

/// Which discount input fields are invalid, if any.
final class DiscountErrors {
  const DiscountErrors({this.price, this.discountPercent});

  final FieldError? price;
  final FieldError? discountPercent;

  bool get hasErrors => price != null || discountPercent != null;
}

/// Validates discount inputs.
DiscountErrors validateDiscountInputs({
  required double price,
  required double discountPercent,
}) => DiscountErrors(
  price: price > 0 ? null : FieldError.mustBePositive,
  discountPercent: discountPercent < 0
      ? FieldError.mustBeNonNegative
      : discountPercent > maxDiscountPercent
      ? FieldError.tooLarge
      : null,
);

/// The computed discount amount and final price.
final class DiscountResult {
  const DiscountResult({
    required this.discountAmount,
    required this.finalPrice,
  });

  final double discountAmount;
  final double finalPrice;
}

/// Computes a discount: `discountAmount = price·discount%/100`,
/// `finalPrice = price−discountAmount`. A 100% discount is a valid free
/// item (`finalPrice = 0`).
DiscountResult? calculateDiscount({
  required double price,
  required double discountPercent,
}) {
  final discountAmount = price * discountPercent / 100;
  final finalPrice = price - discountAmount;
  if (!discountAmount.isFinite || !finalPrice.isFinite) return null;
  return DiscountResult(discountAmount: discountAmount, finalPrice: finalPrice);
}
