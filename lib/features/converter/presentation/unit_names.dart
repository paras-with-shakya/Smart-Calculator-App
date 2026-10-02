import 'package:smart_calculator/features/converter/domain/unit.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// What a screen reader says for [amount] (already formatted, such as
/// "1,28,747.52") of [unit] whose value is [value]: "1,28,747.52 metres".
/// The symbols shown on screen ("m", "ft²", "°C") read badly or not at all.
///
/// An id without a spoken name (a unit added later and not named yet) falls
/// back to the amount and the symbol; `unit_names_test.dart` makes sure no
/// current unit does.
String spokenAmount(
  AppLocalizations l10n,
  ConversionUnit unit,
  num value,
  String amount,
) {
  // A whole number as an int, so "1.0" is read as "1 metre", not "1 metres".
  final count = value == value.roundToDouble() ? value.round() : value;
  return switch (unit.id) {
    'm' => l10n.converterUnitSpokenM(count, amount),
    'km' => l10n.converterUnitSpokenKm(count, amount),
    'cm' => l10n.converterUnitSpokenCm(count, amount),
    'mm' => l10n.converterUnitSpokenMm(count, amount),
    'mile' => l10n.converterUnitSpokenMile(count, amount),
    'yard' => l10n.converterUnitSpokenYard(count, amount),
    'foot' => l10n.converterUnitSpokenFoot(count, amount),
    'inch' => l10n.converterUnitSpokenInch(count, amount),
    'kg' => l10n.converterUnitSpokenKg(count, amount),
    'g' => l10n.converterUnitSpokenG(count, amount),
    'mg' => l10n.converterUnitSpokenMg(count, amount),
    'lb' => l10n.converterUnitSpokenLb(count, amount),
    'oz' => l10n.converterUnitSpokenOz(count, amount),
    'celsius' => l10n.converterUnitSpokenCelsius(count, amount),
    'fahrenheit' => l10n.converterUnitSpokenFahrenheit(count, amount),
    'kelvin' => l10n.converterUnitSpokenKelvin(count, amount),
    'm2' => l10n.converterUnitSpokenM2(count, amount),
    'km2' => l10n.converterUnitSpokenKm2(count, amount),
    'ft2' => l10n.converterUnitSpokenFt2(count, amount),
    'acre' => l10n.converterUnitSpokenAcre(count, amount),
    'hectare' => l10n.converterUnitSpokenHectare(count, amount),
    'l' => l10n.converterUnitSpokenL(count, amount),
    'ml' => l10n.converterUnitSpokenMl(count, amount),
    'gallonUs' => l10n.converterUnitSpokenGallonUs(count, amount),
    'm3' => l10n.converterUnitSpokenM3(count, amount),
    's' => l10n.converterUnitSpokenS(count, amount),
    'min' => l10n.converterUnitSpokenMin(count, amount),
    'h' => l10n.converterUnitSpokenH(count, amount),
    'day' => l10n.converterUnitSpokenDay(count, amount),
    'week' => l10n.converterUnitSpokenWeek(count, amount),
    'usd' => l10n.converterUnitSpokenUsd(count, amount),
    'inr' => l10n.converterUnitSpokenInr(count, amount),
    'eur' => l10n.converterUnitSpokenEur(count, amount),
    'gbp' => l10n.converterUnitSpokenGbp(count, amount),
    _ => '$amount ${unit.symbol}',
  };
}

/// [unit]'s name on its own, plural ("metres", "square feet"): what the unit
/// picker reads out and searches besides the symbol.
String unitName(AppLocalizations l10n, ConversionUnit unit) =>
    spokenAmount(l10n, unit, 2, '').trim();
