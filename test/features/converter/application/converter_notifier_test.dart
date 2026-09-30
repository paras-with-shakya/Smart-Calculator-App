import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/converter/application/converter_notifier.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';

import '../../../helpers/test_app.dart';

void main() {
  late SharedPreferencesWithCache preferences;
  late ProviderContainer container;

  ProviderContainer newContainer() => ProviderContainer.test(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );

  setUp(() async {
    useInMemoryPreferences();
    preferences = await openPreferences();
    container = newContainer();
  });

  ConverterNotifier notifier() => container.read(converterProvider.notifier);
  ConverterState state() => container.read(converterProvider);

  test('starts on Length, its first two units, nothing typed', () {
    expect(state().category, ConversionCategoryId.length);
    expect(state().fromUnitId, 'm');
    expect(state().toUnitId, 'km');
    expect(state().amount.isEmpty, isTrue);
  });

  test('typing digits computes the converted result', () {
    notifier().typeDigit('5');
    expect(state().result, closeTo(0.005, 1e-9)); // 5 m = 0.005 km

    notifier().typeDigit('0');
    expect(state().result, closeTo(0.05, 1e-9)); // 50 m = 0.05 km
  });

  test('the decimal point and backspace edit the amount', () {
    notifier()
      ..typeDigit('1')
      ..typeDecimalPoint()
      ..typeDigit('5');
    expect(state().amount.text, '1.5');

    notifier().backspace();
    expect(state().amount.text, '1.');
  });

  test('clear empties the amount', () {
    notifier()
      ..typeDigit('5')
      ..clear();
    expect(state().amount.isEmpty, isTrue);
    expect(state().result, isNull);
  });

  test('selecting a category starts fresh with its first two units', () {
    notifier()
      ..typeDigit('5')
      ..selectCategory(ConversionCategoryId.temperature);

    expect(state().category, ConversionCategoryId.temperature);
    expect(state().fromUnitId, 'celsius');
    expect(state().toUnitId, 'fahrenheit');
    expect(state().amount.isEmpty, isTrue);
  });

  test('selecting from/to units changes what is converted', () {
    notifier()
      ..selectFromUnit('mile')
      ..selectToUnit('foot')
      ..typeDigit('1');

    expect(state().result, closeTo(5280, 1e-6));
  });

  test('swap exchanges the units and keeps the typed text', () {
    notifier()
      ..typeDigit('1')
      ..swap();

    expect(state().fromUnitId, 'km');
    expect(state().toUnitId, 'm');
    expect(state().amount.text, '1');
    expect(state().result, closeTo(1000, 1e-9)); // 1 km = 1000 m
  });

  group('sign (temperature only)', () {
    test('is refused outside temperature', () {
      notifier().toggleSign();
      expect(state().amount.isNegative, isFalse);
    });

    test('is allowed for temperature', () {
      notifier()
        ..selectCategory(ConversionCategoryId.temperature)
        ..toggleSign()
        ..typeDigit('4')
        ..typeDigit('0');

      expect(state().amount.text, '-40');
      expect(state().result, closeTo(-40, 1e-9)); // -40°C = -40°F
    });
  });

  group('currency', () {
    test('starts with the default example rates', () {
      notifier().selectCategory(ConversionCategoryId.currency);

      expect(state().fromUnitId, 'usd');
      expect(state().currencyRates['inr'], 83);
    });

    test('setCurrencyRate updates the live conversion immediately', () async {
      notifier().selectCategory(ConversionCategoryId.currency);
      await notifier().setCurrencyRate('inr', 90);
      notifier().typeDigit('1');

      expect(state().result, closeTo(90, 1e-9));
    });

    test('a non-positive rate is refused', () async {
      notifier().selectCategory(ConversionCategoryId.currency);
      await notifier().setCurrencyRate('inr', 0);
      await notifier().setCurrencyRate('inr', -5);

      expect(state().currencyRates['inr'], 83);
    });
  });

  group('persistence', () {
    test('category, units and a currency rate survive a restart', () async {
      notifier()
        ..selectCategory(ConversionCategoryId.weight)
        ..selectFromUnit('lb')
        ..selectToUnit('oz');
      await notifier().setCurrencyRate('eur', 0.95);

      final restarted = newContainer();
      addTearDown(restarted.dispose);

      final restartedState = restarted.read(converterProvider);
      expect(restartedState.category, ConversionCategoryId.weight);
      expect(restartedState.fromUnitId, 'lb');
      expect(restartedState.toUnitId, 'oz');
      expect(restartedState.currencyRates['eur'], 0.95);
    });
  });
}
