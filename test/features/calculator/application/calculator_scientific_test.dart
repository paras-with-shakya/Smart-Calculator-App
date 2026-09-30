import 'dart:math';

import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
import 'package:smart_calculator/features/settings/application/angle_mode_notifier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/expression_text.dart';
import '../../../helpers/test_app.dart';

const Map<String, CalculatorKey> _keys = {
  '.': CalculatorKey.decimalPoint,
  '+': CalculatorKey.add,
  '−': CalculatorKey.subtract,
  '×': CalculatorKey.multiply,
  '÷': CalculatorKey.divide,
  '%': CalculatorKey.percent,
  '^': CalculatorKey.power,
  '!': CalculatorKey.factorial,
  'p': CalculatorKey.pi,
  'E': CalculatorKey.euler,
  's': CalculatorKey.sin,
  'c': CalculatorKey.cos,
  't': CalculatorKey.tan,
  'a': CalculatorKey.asin,
  'q': CalculatorKey.sqrt,
  'l': CalculatorKey.ln,
  'g': CalculatorKey.log,
  'r': CalculatorKey.cbrt,
  'v': CalculatorKey.abs,
  'x': CalculatorKey.square,
  'y': CalculatorKey.cube,
  'T': CalculatorKey.powerOfTen,
  'F': CalculatorKey.powerOfE,
  '(': CalculatorKey.openBracket,
  ')': CalculatorKey.closeBracket,
  'b': CalculatorKey.brackets,
  '<': CalculatorKey.backspace,
  'C': CalculatorKey.allClear,
  '=': CalculatorKey.equals,
};

void main() {
  setUpAll(sqfliteFfiInit);

  late SharedPreferencesWithCache preferences;
  late ProviderContainer container;

  ProviderContainer newContainer() => ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      appDatabaseProvider.overrideWith(
        (ref) => AppDatabase.open(
          databaseFactoryFfiNoIsolate,
          inMemoryDatabasePath,
          singleInstance: false,
        ),
      ),
    ],
  );

  setUp(() async {
    useInMemoryPreferences();
    preferences = await openPreferences();
    container = newContainer();
  });

  CalculatorNotifier calculator() =>
      container.read(calculatorProvider.notifier);
  CalculatorState state() => container.read(calculatorProvider);
  String? valueText() => state().value?.toDecimalString();
  String? resultText() => state().result?.toDecimalString();
  AngleModeNotifier angle() => container.read(angleModeProvider.notifier);

  void press(String keys) {
    for (final key in keys.split('')) {
      calculator().press(_keys[key] ?? CalculatorKey.digit(int.parse(key)));
    }
  }

  group('scientific keys', () {
    test('type a power and a factorial', () {
      press('2^3!');

      expect(show(state().buffer), '2^3!|');
      expect(valueText(), '64');
    });

    test('a function opens a call that is closed for the value', () {
      press('q9');

      expect(show(state().buffer), 'sqrt(9|');
      expect(valueText(), '3');

      press('=');
      expect(resultText(), '3');
    });

    test('π and e insert the constants, with × between operands', () {
      press('2p');
      expect(valueText(), '6.28318530718');

      press('CE');
      expect(valueText(), '2.71828182846');
    });

    test('an operator, ^ or ! continues from the answer', () {
      press('2×3=');
      press('^2=');
      expect(resultText(), '36');

      press('C3=');
      press('!=');
      expect(resultText(), '6');
    });

    test('a function or constant after = starts a new expression', () {
      press('2+3=');
      press('q');

      expect(show(state().buffer), 'sqrt(|');
      expect(state().showsResult, isFalse);
    });

    test('a history entry keeps the engine names', () async {
      press('5!=');
      await pumpEventQueue();

      final entries = await container.read(historyProvider.future);
      expect(entries.single.expression, '5!');
      expect(entries.single.result.toDecimalString(), '120');
    });
  });

  group('power-of keys (x², x³, 10ˣ, eˣ)', () {
    test('square and cube apply to what was already typed', () {
      press('5x');
      expect(show(state().buffer), '5^2|');
      expect(valueText(), '25');

      press('C5y');
      expect(show(state().buffer), '5^3|');
      expect(valueText(), '125');
    });

    test('10ˣ and eˣ start a fresh value, ready for the exponent', () {
      press('T2');
      expect(show(state().buffer), '{10}^2|');
      expect(valueText(), '100');

      press('CF0');
      expect(show(state().buffer), 'e^0|');
      expect(valueText(), '1');
    });

    test('square and cube continue from the answer, like ^ and !', () {
      press('2×3=');
      press('x=');
      expect(resultText(), '36');
    });

    test('10ˣ and eˣ start a new expression after =, like a function key', () {
      press('2+3=');
      press('T');

      expect(show(state().buffer), '{10}^|');
      expect(state().showsResult, isFalse);
    });

    test('refused where there is no operand, or one already follows', () {
      press('Cx');
      expect(state().buffer.isEmpty, isTrue);

      press('C(x');
      expect(show(state().buffer), '(|');

      press('C5');
      calculator().moveCursor(-1);
      press('T');
      expect(show(state().buffer), '|5');
    });
  });

  group('angle mode', () {
    test('defaults to degrees', () {
      expect(container.read(angleModeProvider), AngleMode.degrees);
    });

    test('sin(30) is 0.5 in degrees', () {
      press('s30');

      expect(valueText(), '0.5');
    });

    test('changing the mode recomputes the live value', () async {
      press('s30');
      expect(valueText(), '0.5');

      await angle().setMode(AngleMode.radians);

      expect(valueText(), '-0.988031624093');
      expect(show(state().buffer), 'sin(30|', reason: 'the input is kept');

      await angle().toggle();
      expect(valueText(), '0.5');
    });

    test('the mode is used when = is pressed', () async {
      await angle().setMode(AngleMode.radians);
      press('sp÷2)=');

      expect(resultText(), '1');
    });

    test('an answer already shown is not recomputed', () async {
      press('s30)=');
      expect(resultText(), '0.5');

      await angle().toggle();

      expect(resultText(), '0.5');
      expect(state().showsResult, isTrue);
    });

    test('the mode change refreshes an error too', () async {
      // tan(90) is undefined in degrees, an ordinary number in radians.
      press('t90)=');
      expect(state().error, CalcError.undefined);

      await angle().toggle();

      expect(state().error, isNull);
      expect(valueText(), '-1.99520041221');
    });

    test('is remembered after a restart', () async {
      await angle().setMode(AngleMode.radians);

      expect(preferences.getString(PreferenceKeys.angleMode), 'radians');
      final restarted = newContainer();
      addTearDown(restarted.dispose);
      expect(restarted.read(angleModeProvider), AngleMode.radians);
    });
  });

  group('wrong and impossible input is handled', () {
    /// Types [keys], presses `=`, and checks the calculator reports [error]
    /// and keeps the expression editable.
    void expectError(String keys, CalcError error) {
      test('"$keys" → ${error.name}', () {
        press(keys);
        press('=');

        expect(state().error, error);
        expect(state().showsResult, isFalse);
        expect(state().buffer.isEmpty, isFalse, reason: 'still editable');
      });
    }

    expectError('t90)', CalcError.undefined);
    expectError('q−4)', CalcError.undefined);
    expectError('l0)', CalcError.undefined);
    expectError('g0)', CalcError.undefined);
    expectError('a2)', CalcError.undefined);
    expectError('0^−1', CalcError.undefined);
    expectError('(−8)^0.5', CalcError.undefined);
    expectError('3.5!', CalcError.undefined);
    expectError('(−3)!', CalcError.undefined);
    expectError('0÷0', CalcError.divisionByZero);
    expectError('5÷0', CalcError.divisionByZero);
    expectError('1÷(2−2)', CalcError.divisionByZero);
    expectError('100!', CalcError.overflow);
    expectError('99999999999999!', CalcError.overflow);
    expectError('9^9^9', CalcError.overflow);
    expectError('10^100', CalcError.overflow);
    expectError('2^99999999', CalcError.overflow);
    expectError('s5+', CalcError.incomplete);
    expectError('2^', CalcError.incomplete);
    expectError('q', CalcError.incomplete);
    expectError('(', CalcError.incomplete);

    test('an error can be fixed by editing, without starting over', () {
      press('t90)=');
      expect(state().error, CalcError.undefined);

      press('<<<');
      press('45)');
      expect(state().error, isNull);
      expect(valueText(), '1');

      press('=');
      expect(resultText(), '1');
    });

    test('keys that make no sense at the start change nothing', () {
      for (final keys in ['^', '!', ')', '%', '×', '+']) {
        press('C$keys');
        expect(state().buffer.isEmpty, isTrue, reason: 'first key "$keys"');
      }
      press('C5^!');
      expect(show(state().buffer), '5^|');
    });

    test('a stray key does not wipe an answer', () {
      press('2^3=');
      expect(resultText(), '8');

      press(')');
      expect(resultText(), '8');
    });

    test('the input length limit holds', () {
      for (var i = 0; i < 300; i++) {
        press('s');
      }
      expect(state().buffer.units.length, lessThanOrEqualTo(100));

      press('=');
      expect(state().error, isNotNull);
    });

    test('typed text: symbols work, names and letters are refused', () {
      expect(calculator().typeText('2^3!'), isTrue);
      expect(show(state().buffer), '2^3!|');

      press('C');
      expect(calculator().typeText('π×2'), isTrue);
      expect(show(state().buffer), 'π×2|');

      press('C');
      expect(calculator().typeText('sin(30)'), isFalse);
      expect(calculator().typeText('1.5e12'), isFalse);
      expect(state().buffer.isEmpty, isTrue);
    });

    test('random key sequences never throw, and keep the state sane', () {
      final random = Random(20260929);
      const alphabet = '0123456789.+−×÷%^!pEsctaqlgrvxyTF()b<=';

      for (var run = 0; run < 400; run++) {
        press('C');
        for (var step = 0; step < 30; step++) {
          final key = alphabet[random.nextInt(alphabet.length)];
          final before = show(state().buffer);
          expect(
            () => press(key),
            returnsNormally,
            reason: 'run $run, "$key" after "$before"',
          );
          final current = state();
          expect(current.buffer.units.length, lessThanOrEqualTo(100));
          expect(
            current.result != null && current.error != null,
            isFalse,
            reason: 'never an answer and an error together',
          );
          if (current.error != null) {
            expect(current.buffer.isEmpty, isFalse);
          }
          expect(current.buffer.openBrackets, greaterThanOrEqualTo(0));
        }
      }
    });

    test('anything the buffer builds, the engine reads without throwing', () {
      final random = Random(7);
      const alphabet = '0123456789.+−×÷%^!pEsctaqlgrvxyTF()b<';
      const engine = CalcEngine();

      for (var run = 0; run < 400; run++) {
        press('C');
        for (var step = 0; step < 40; step++) {
          press(alphabet[random.nextInt(alphabet.length)]);
        }
        final input = state().buffer.withBracketsClosed.toEngineInput();
        for (final mode in AngleMode.values) {
          expect(
            () => engine.evaluate(
              input.expression,
              variables: input.variables,
              angleMode: mode,
            ),
            returnsNormally,
            reason: input.expression,
          );
        }
      }
    });
  });
}
