/// A reason a financial input field failed validation.
///
/// The presentation layer maps this to a localized message. [tooLarge]'s
/// specific numeric bound lives at the call site (each tool's own `max...`
/// constant), not here, since domain code stays free of localization.
enum FieldError {
  /// The field must be greater than zero.
  mustBePositive,

  /// The field must be zero or greater.
  mustBeNonNegative,

  /// The field exceeds its sane upper bound.
  tooLarge,

  /// The field must be a whole number of at least 1.
  mustBePositiveInteger,
}
