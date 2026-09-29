import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/core/persistence/app_database.dart';
import 'package:smart_calculator/core/persistence/database_providers.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/application/memory_notifier.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
import 'package:smart_calculator/features/history/domain/history_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/expression_text.dart';
import '../../../helpers/test_app.dart';

/// The value of [literal], which may start with `-`.
CalcValue n(String literal) => literal.startsWith('-')
    ? -CalcValue.parse(literal.substring(1))
    : CalcValue.parse(literal);

final CalcValue third = n('1') / n('3');

const Map<String, CalculatorKey> _keys = {
  '.': CalculatorKey.decimalPoint,
  '+': CalculatorKey.add,
  '−': CalculatorKey.subtract,
  '×': CalculatorKey.multiply,
  '÷': CalculatorKey.divide,
  '%': CalculatorKey.percent,
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
  CalcValue? memory() => container.read(memoryProvider);
  Future<List<HistoryEntry>> history() =>
      container.read(historyProvider.future);

  /// Presses [keys]: digits, and the symbols in [_keys].
  void press(String keys) {
    for (final key in keys.split('')) {
      calculator().press(_keys[key] ?? CalculatorKey.digit(int.parse(key)));
    }
  }

  group('while typing', () {
    test('starts empty', () {
      expect(state(), const CalculatorState());
      expect(state().currentValue, isNull);
    });

    test('shows the live value of an expression', () {
      press('5+3');

      expect(show(state().buffer), '5+3|');
      expect(state().value, n('8'));
      expect(state().showsPreview, isTrue);
      expect(state().showsResult, isFalse);
      expect(state().currentValue, n('8'));
    });

    test('has no preview for a single number', () {
      press('5');

      expect(state().value, n('5'));
      expect(state().showsPreview, isFalse);
    });

    test('has no value while the expression is unfinished or invalid', () {
      press('5×');
      expect(state().value, isNull);
      expect(state().showsPreview, isFalse);

      press('C5÷0');
      expect(state().value, isNull);
    });

    test('previews with open brackets closed', () {
      press('2×(5+3');

      expect(state().value, n('16'));
    });

    test('previews smart percent', () {
      press('50+10%');

      expect(state().value, n('55'));
    });
  });

  group('equals', () {
    test('shows the result and the expression it came from', () {
      press('5+3=');

      expect(state().result, n('8'));
      expect(show(state().evaluatedExpression!), '5+3|');
      expect(state().buffer.isEmpty, isTrue);
      expect(state().showsResult, isTrue);
      expect(state().showsPreview, isFalse);
      expect(state().currentValue, n('8'));
    });

    test('closes open brackets', () {
      press('(5+3=');

      expect(state().result, n('8'));
      expect(show(state().evaluatedExpression!), '(5+3)|');
    });

    test('does nothing on an empty display', () {
      press('=');

      expect(state(), const CalculatorState());
    });

    test('pressed again keeps the result', () {
      press('5+3=');
      final afterFirst = state();

      press('=');

      expect(state(), afterFirst);
    });

    const smartPercent = {
      '50+10%=': '55',
      '50−10%=': '45',
      '50×10%=': '5',
      '50÷10%=': '500',
      '10%=': '0.1',
      '200+5%+5%=': '220.5',
    };
    smartPercent.forEach((keys, expected) {
      test('smart percent: $keys $expected', () {
        press(keys);

        expect(state().result, n(expected));
      });
    });

    test('is exact', () {
      press('0.1+0.2=');
      expect(state().result, n('0.3'));

      press('1÷3=');
      expect(state().result, third);
    });
  });

  group('history', () {
    test('a successful "=" adds an entry, newest first', () async {
      press('5+3=');
      await pumpEventQueue();
      press('C1÷3=');
      await pumpEventQueue();

      final entries = await history();
      expect(entries, hasLength(2));
      expect(entries[0].result, third);
      expect(entries[0].expression, '1÷3');
      expect(entries[0].mode, CalculatorMode.basic);
      expect(entries[1].result, n('8'));
      expect(entries[1].expression, '5+3');
    });

    test('an error does not add an entry', () async {
      press('5÷0=');
      await pumpEventQueue();

      expect(await history(), isEmpty);
    });

    test('reflects the mode "=" was pressed in', () async {
      container
          .read(currentModeProvider.notifier)
          .select(CalculatorMode.scientific);
      press('5+3=');
      await pumpEventQueue();

      expect((await history()).single.mode, CalculatorMode.scientific);
    });
  });

  group('reusing a history entry', () {
    test('inserts the exact result, like MR', () {
      calculator().useHistoryResult(third);

      expect(show(state().buffer), '{1/3}|');
      expect(state().value, third);
    });

    test('starts a new expression after a result', () {
      press('5+3=');

      calculator().useHistoryResult(n('2'));

      expect(show(state().buffer), '{2}|');
    });
  });

  group('after a result', () {
    test('a digit starts a new expression', () {
      press('5+3=2');

      expect(show(state().buffer), '2|');
      expect(state().result, isNull);
      expect(state().evaluatedExpression, isNull);
    });

    test('the decimal point and brackets start a new expression', () {
      press('5+3=.');
      expect(show(state().buffer), '0.|');

      press('C5+3=(');
      expect(show(state().buffer), '(|');
    });

    test('an operator continues from the exact result', () {
      press('5+3=+2');
      expect(show(state().buffer), '{8}+2|');
      expect(state().value, n('10'));

      press('C1÷3=×3=');
      expect(state().result, n('1'));
    });

    test('percent continues from the result', () {
      press('5+3=%');

      expect(show(state().buffer), '{8}%|');
      expect(state().value, n('0.08'));
    });

    test('results chain', () {
      press('2×3=×4=−4=');

      expect(state().result, n('20'));
    });

    test('backspace clears the result', () {
      press('5+3=<');

      expect(state(), const CalculatorState());
    });

    test('a key the input rules refuse keeps the result', () {
      press('5+3=)');

      expect(state().result, n('8'));
    });

    test('AC clears everything', () {
      press('5+3=C');

      expect(state(), const CalculatorState());
    });
  });

  group('errors', () {
    test('division by zero is reported, and the expression kept', () {
      press('5÷0=');

      expect(state().error, CalcError.divisionByZero);
      expect(show(state().buffer), '5÷0|');
      expect(state().result, isNull);
      expect(state().showsResult, isFalse);
      expect(state().showsPreview, isFalse);
    });

    test('an unfinished expression is reported as incomplete', () {
      for (final keys in ['5+=', '(5+=', '5×(=', '−=']) {
        press('C$keys');
        expect(state().error, CalcError.incomplete, reason: keys);
      }
    });

    test('a result too large to show is an overflow', () {
      const nines = '999999999999999';
      press('$nines×$nines×$nines=');
      press('×$nines×$nines×$nines=');
      expect(state().error, isNull);

      press('×$nines×$nines×$nines=');

      expect(state().error, CalcError.overflow);
    });

    test('the next edit clears the error and edits the expression', () {
      press('5÷0=<');
      expect(state().error, isNull);
      expect(show(state().buffer), '5÷|');

      press('1');
      expect(state().value, n('5'));
    });

    test('a digit fixes the expression in place', () {
      press('5÷0=2');

      expect(state().error, isNull);
      expect(show(state().buffer), '5÷2|');
      expect(state().value, n('2.5'));
    });

    test('a key the input rules refuse keeps the error', () {
      press('5÷0=)');

      expect(state().error, CalcError.divisionByZero);
    });

    test('moving the cursor keeps the error', () {
      press('5÷0=');
      calculator().moveCursor(-1);

      expect(state().error, CalcError.divisionByZero);
      expect(show(state().buffer), '5÷|0');
    });

    test('AC clears the error', () {
      press('5÷0=C');

      expect(state(), const CalculatorState());
    });
  });

  group('editing in the middle (known limitation, DEVELOPMENT_STATUS.md '
      '"Calculator limitations")', () {
    // The input rules only look at the unit right before the cursor, so
    // moving the cursor before an existing operator and typing a new one
    // does not collapse the two the way typing normally does.
    test('can silently reinterpret the expression, rather than error', () {
      press('5+3');
      calculator().moveCursor(-2); // between "5" and "+"
      press('×');

      expect(show(state().buffer), '5×|+3');

      press('=');

      // Not a bug: "+3" is a valid unary-plus operand, so "5×+3" is "5×3".
      expect(state().error, isNull);
      expect(state().result, n('15'));
    });

    test('can also produce a genuine, safely-handled syntax error', () {
      press('5%');
      calculator().moveCursor(-1); // between "5" and "%"
      press('×');

      expect(show(state().buffer), '5×|%');

      press('=');

      expect(state().error, CalcError.syntax);
      expect(show(state().buffer), '5×|%');
      expect(state().showsResult, isFalse);
    });
  });

  group('the cursor', () {
    test('edits happen at the cursor', () {
      press('123');
      calculator().moveCursor(-1);
      press('4');

      expect(show(state().buffer), '124|3');
      expect(state().value, n('1243'));
    });

    test('can be put anywhere', () {
      press('123');
      calculator().setCursor(0);
      press('−');

      expect(show(state().buffer), '−|123');
      expect(state().value, n('-123'));
    });

    test('stays inside the expression', () {
      press('12');
      calculator().moveCursor(-5);
      expect(state().buffer.cursor, 0);

      calculator().moveCursor(9);
      expect(state().buffer.cursor, 2);
    });

    test('does not move on a result', () {
      press('5+3=');
      final result = state();

      calculator().setCursor(0);

      expect(state(), result);
    });
  });

  group('typing text', () {
    test('types each character as its key', () {
      expect(calculator().typeText('12+3'), isTrue);

      expect(show(state().buffer), '12+3|');
      expect(state().value, n('15'));
    });

    test('accepts keyboard spellings of the operators', () {
      calculator().typeText('6*7-8/2x3');

      expect(show(state().buffer), '6×7−8÷2×3|');
    });

    test('skips whitespace', () {
      expect(calculator().typeText(' 2 × 3 '), isTrue);

      expect(show(state().buffer), '2×3|');
    });

    test('can evaluate', () {
      calculator().typeText('2+3=');

      expect(state().result, n('5'));
    });

    test('types nothing if any character is not calculator input', () {
      press('7');

      expect(calculator().typeText('1.5e12'), isFalse);
      expect(calculator().typeText('12abc'), isFalse);
      expect(show(state().buffer), '7|');
    });

    test('reports empty text as not typed', () {
      expect(calculator().typeText(''), isFalse);
      expect(calculator().typeText('  '), isFalse);
      expect(state(), const CalculatorState());
    });
  });

  group('memory', () {
    test('starts empty', () {
      expect(memory(), isNull);
    });

    test('MS stores the live value, or the result', () async {
      press('5+3');
      await calculator().memoryStore();
      expect(memory(), n('8'));

      press('=×2=');
      await calculator().memoryStore();
      expect(memory(), n('16'));
    });

    test('M+ and M− add to and subtract from it', () async {
      press('4');
      await calculator().memoryAdd();
      expect(memory(), n('4'));

      press('C10=');
      await calculator().memoryAdd();
      expect(memory(), n('14'));

      press('C1.5');
      await calculator().memorySubtract();
      expect(memory(), n('12.5'));
    });

    test('M− on an empty memory stores the negative', () async {
      press('3');
      await calculator().memorySubtract();

      expect(memory(), n('-3'));
    });

    test('MC empties it', () async {
      press('5');
      await calculator().memoryStore();

      await calculator().memoryClear();

      expect(memory(), isNull);
    });

    test('does nothing without a current value', () async {
      await calculator().memoryStore();
      press('5+');
      await calculator().memoryStore();
      await calculator().memoryAdd();

      expect(memory(), isNull);
    });

    test('is independent of AC', () async {
      press('5');
      await calculator().memoryStore();

      press('C');

      expect(memory(), n('5'));
    });

    test('MR inserts it', () async {
      press('8');
      await calculator().memoryStore();

      press('C');
      calculator().memoryRecall();
      expect(show(state().buffer), '{8}|');
      expect(state().value, n('8'));

      press('C2');
      calculator().memoryRecall();
      expect(show(state().buffer), '2×{8}|');
      expect(state().value, n('16'));
    });

    test('MR after a result starts a new expression', () async {
      press('8');
      await calculator().memoryStore();

      press('1+1=');
      calculator().memoryRecall();

      expect(show(state().buffer), '{8}|');
      expect(state().result, isNull);
    });

    test('MR does nothing when the memory is empty', () {
      press('5+3=');
      final result = state();

      calculator().memoryRecall();

      expect(state(), result);
    });

    test('keeps values exact', () async {
      press('1÷3=');
      await calculator().memoryStore();

      press('C');
      calculator().memoryRecall();
      press('×3=');

      expect(state().result, n('1'));
    });

    test('survives a restart, exactly', () async {
      press('1÷3=');
      await calculator().memoryStore();

      final restarted = newContainer();

      expect(restarted.read(memoryProvider), third);
    });

    test('is saved as an exact fraction under its key', () async {
      press('1÷3=');
      await calculator().memoryStore();
      expect(preferences.getString(PreferenceKeys.calculatorMemory), '1/3');

      await calculator().memoryClear();
      expect(preferences.containsKey(PreferenceKeys.calculatorMemory), isFalse);
    });

    test('ignores a saved value it cannot read', () async {
      await preferences.setString(PreferenceKeys.calculatorMemory, 'twelve');

      expect(newContainer().read(memoryProvider), isNull);
    });

    test('refuses a value too large to show, and keeps its value', () async {
      final notifier = container.read(memoryProvider.notifier);
      final nearLimit = n('9${'0' * 99}');
      await notifier.store(nearLimit);

      await notifier.store(n('1${'0' * 100}'));
      expect(memory(), nearLimit);

      await notifier.add(nearLimit);
      expect(memory(), nearLimit);
      expect(
        CalcValue.tryParseStorage(
          preferences.getString(PreferenceKeys.calculatorMemory)!,
        ),
        nearLimit,
      );
    });
  });

  test('the state describes itself', () {
    press('5÷0=');

    expect(
      state().toString(),
      'CalculatorState(ExpressionBuffer(5÷0|), value: null, result: null, '
      'error: CalcError.divisionByZero, evaluated: null)',
    );
  });
}
