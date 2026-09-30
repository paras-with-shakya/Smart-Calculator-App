import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/converter/domain/conversion_tables.dart';
import 'package:smart_calculator/features/converter/domain/number_entry_buffer.dart';
import 'package:smart_calculator/features/settings/data/preferences_settings_repository.dart';

/// What the converter shows: the current category, its two selected units,
/// the typed amount and the live currency rates (only meaningful while
/// [category] is [ConversionCategoryId.currency]).
final class ConverterState {
  /// Creates a state.
  const ConverterState({
    required this.category,
    required this.fromUnitId,
    required this.toUnitId,
    this.amount = NumberEntryBuffer.empty,
    this.currencyRates = const {},
  });

  /// The category currently shown.
  final ConversionCategoryId category;

  /// The unit the typed amount is in.
  final String fromUnitId;

  /// The unit the result is shown in.
  final String toUnitId;

  /// The amount being typed, in [fromUnitId].
  final NumberEntryBuffer amount;

  /// The current "per 1 USD" rate for every currency id, kept here (not
  /// re-read per conversion) so editing a rate updates the result
  /// immediately.
  final Map<String, double> currencyRates;

  /// The active category's conversion table: the six physical categories'
  /// fixed data, or currency's table built from the live [currencyRates].
  ConversionCategory get table => category == ConversionCategoryId.currency
      ? currencyCategory(currencyRates)
      : physicalCategories.firstWhere((c) => c.id == category);

  /// The converted amount, or null while [amount] has nothing typed.
  double? get result {
    final value = amount.value;
    if (value == null) return null;
    return table.convert(value, from: fromUnitId, to: toUnitId);
  }

  /// This state with the given fields replaced.
  ConverterState copyWith({
    ConversionCategoryId? category,
    String? fromUnitId,
    String? toUnitId,
    NumberEntryBuffer? amount,
    Map<String, double>? currencyRates,
  }) => ConverterState(
    category: category ?? this.category,
    fromUnitId: fromUnitId ?? this.fromUnitId,
    toUnitId: toUnitId ?? this.toUnitId,
    amount: amount ?? this.amount,
    currencyRates: currencyRates ?? this.currencyRates,
  );

  @override
  bool operator ==(Object other) =>
      other is ConverterState &&
      other.category == category &&
      other.fromUnitId == fromUnitId &&
      other.toUnitId == toUnitId &&
      other.amount == amount &&
      _mapEquals(other.currencyRates, currencyRates);

  @override
  int get hashCode => Object.hash(
    category,
    fromUnitId,
    toUnitId,
    amount,
    Object.hashAllUnordered(
      currencyRates.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}

/// The converter's state, independent of the calculator (DEC-013's reason
/// for Basic and Scientific sharing state — one cursor, one memory, one
/// history — doesn't apply here: a conversion has none of those).
final NotifierProvider<ConverterNotifier, ConverterState> converterProvider =
    NotifierProvider<ConverterNotifier, ConverterState>(ConverterNotifier.new);

/// Turns converter actions into states, and saves the category, units and
/// any edited currency rate so the app reopens where it left off.
class ConverterNotifier extends Notifier<ConverterState> {
  @override
  ConverterState build() {
    final repository = ref.watch(settingsRepositoryProvider);
    final category =
        repository.lastConverterCategory ?? ConversionCategoryId.length;
    final rates = {
      for (final id in currencyIds) id: repository.currencyRate(id),
    };
    final table = category == ConversionCategoryId.currency
        ? currencyCategory(rates)
        : physicalCategories.firstWhere((c) => c.id == category);
    final savedUnits = repository.lastConverterUnits;
    final validSaved =
        savedUnits != null &&
        table.units.any((u) => u.id == savedUnits.$1) &&
        table.units.any((u) => u.id == savedUnits.$2);
    return ConverterState(
      category: category,
      fromUnitId: validSaved ? savedUnits.$1 : table.units.first.id,
      toUnitId: validSaved
          ? savedUnits.$2
          : table.units[table.units.length > 1 ? 1 : 0].id,
      currencyRates: rates,
    );
  }

  /// Switches to [category], starting fresh with its first two units.
  void selectCategory(ConversionCategoryId category) {
    final table = category == ConversionCategoryId.currency
        ? currencyCategory(state.currencyRates)
        : physicalCategories.firstWhere((c) => c.id == category);
    state = state.copyWith(
      category: category,
      fromUnitId: table.units.first.id,
      toUnitId: table.units[table.units.length > 1 ? 1 : 0].id,
      amount: NumberEntryBuffer.empty,
    );
    _persistCategoryAndUnits();
  }

  /// Changes the unit the typed amount is in.
  void selectFromUnit(String unitId) {
    state = state.copyWith(fromUnitId: unitId);
    _persistCategoryAndUnits();
  }

  /// Changes the unit the result is shown in.
  void selectToUnit(String unitId) {
    state = state.copyWith(toUnitId: unitId);
    _persistCategoryAndUnits();
  }

  /// Swaps the from/to units. The typed amount's *text* stays exactly as
  /// it was — it's now interpreted in the other unit, which naturally
  /// gives a new result — rather than trying to re-type the previous
  /// result's value, which would need its own number-to-text formatting
  /// (with its own edge cases, such as very small/large values) just to
  /// undo the split this buffer exists to avoid.
  void swap() {
    state = state.copyWith(
      fromUnitId: state.toUnitId,
      toUnitId: state.fromUnitId,
    );
    _persistCategoryAndUnits();
  }

  /// Types [digit] (0-9) into the amount.
  void typeDigit(String digit) => _edit(state.amount.insertDigit(digit));

  /// Types the decimal point into the amount.
  void typeDecimalPoint() => _edit(state.amount.insertDecimalPoint());

  /// Toggles the amount's sign (temperature only — every other category
  /// refuses this at the buffer level regardless).
  void toggleSign() =>
      _edit(state.amount.toggleSign(allowed: state.table.allowsNegative));

  /// Removes the last typed character.
  void backspace() => _edit(state.amount.backspace());

  /// Clears the typed amount.
  void clear() => _edit(NumberEntryBuffer.empty);

  /// Sets currency [currencyId]'s "per 1 USD" rate. Refused (no-op) for a
  /// non-positive rate — a zero or negative exchange rate has no meaning.
  Future<void> setCurrencyRate(String currencyId, double rate) async {
    if (rate <= 0) return;
    state = state.copyWith(
      currencyRates: {...state.currencyRates, currencyId: rate},
    );
    await ref
        .read(settingsRepositoryProvider)
        .setCurrencyRate(currencyId, rate);
  }

  void _edit(NumberEntryBuffer amount) {
    state = state.copyWith(amount: amount);
  }

  void _persistCategoryAndUnits() {
    final repository = ref.read(settingsRepositoryProvider);
    unawaited(repository.setLastConverterCategory(state.category));
    unawaited(
      repository.setLastConverterUnits(state.fromUnitId, state.toUnitId),
    );
  }
}

bool _mapEquals(Map<String, double> a, Map<String, double> b) {
  if (a.length != b.length) return false;
  for (final MapEntry(key: key, value: value) in a.entries) {
    if (b[key] != value) return false;
  }
  return true;
}
