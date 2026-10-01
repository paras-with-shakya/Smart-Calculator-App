import 'package:smart_calculator/features/financial/domain/validation.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The localized message for [error], or null if there's no error. [max] is
/// required for [FieldError.tooLarge] — the field's own numeric bound, read
/// from the domain file's `max...` constant at the call site, since domain
/// code itself stays free of localization.
String? fieldErrorMessage(
  AppLocalizations l10n,
  FieldError? error, {
  int? max,
}) {
  if (error == null) return null;
  return switch (error) {
    FieldError.mustBePositive => l10n.financialErrorMustBePositive,
    FieldError.mustBeNonNegative => l10n.financialErrorMustBeNonNegative,
    FieldError.tooLarge => l10n.financialErrorTooLarge(max!),
    FieldError.mustBePositiveInteger =>
      l10n.financialErrorMustBePositiveInteger,
  };
}
