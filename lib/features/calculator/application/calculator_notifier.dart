import 'dart:async';

import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/features/calculator/application/memory_notifier.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/calculator/domain/expression_buffer.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
import 'package:smart_calculator/features/settings/application/angle_mode_notifier.dart';

/// What the calculator shows.
///
/// While typing, [buffer] holds the expression and [value] its live value.
/// After `=`, either [result] holds the answer (with [evaluatedExpression]
/// above it), or [error] explains the failure and [buffer] stays editable.
final class CalculatorState {
  /// Creates a state; the default is the empty calculator.
  const CalculatorState({
    this.buffer = ExpressionBuffer.empty,
    this.value,
    this.result,
    this.error,
    this.evaluatedExpression,
  });

  /// The expression being typed.
  final ExpressionBuffer buffer;

  /// The value of [buffer], with open brackets closed; null when it has
  /// none (empty, incomplete or invalid).
  final CalcValue? value;

  /// The answer after `=`.
  final CalcValue? result;

  /// Why `=` failed.
  final CalcError? error;

  /// The expression [result] came from, with brackets closed.
  final ExpressionBuffer? evaluatedExpression;

  /// Whether the display shows an answer rather than the expression.
  bool get showsResult => result != null;

  /// Whether a live preview is worth showing: the expression has a value
  /// and more than a single number.
  bool get showsPreview =>
      value != null && result == null && error == null && !buffer.isPlainNumber;

  /// The value M+, M− and MS use: the answer, or the expression's value.
  CalcValue? get currentValue => result ?? value;

  @override
  bool operator ==(Object other) =>
      other is CalculatorState &&
      other.buffer == buffer &&
      other.value == value &&
      other.result == result &&
      other.error == error &&
      other.evaluatedExpression == evaluatedExpression;

  @override
  int get hashCode =>
      Object.hash(buffer, value, result, error, evaluatedExpression);

  @override
  String toString() =>
      'CalculatorState($buffer, value: $value, result: $result, '
      'error: $error, evaluated: $evaluatedExpression)';
}

/// The calculator: basic now, and shared with scientific mode (DEC-013).
final NotifierProvider<CalculatorNotifier, CalculatorState> calculatorProvider =
    NotifierProvider<CalculatorNotifier, CalculatorState>(
      CalculatorNotifier.new,
    );

/// Turns key presses into calculator states.
///
/// After `=`:
/// - a digit, the decimal point or a bracket starts a new expression;
/// - an operator or `%` continues from the exact answer (`1÷3=` then `×3=`
///   gives exactly 1);
/// - backspace clears the answer;
/// - memory recall starts a new expression with the memory.
///
/// After a failed `=`, the error shows until the next edit, which applies
/// to the same expression so it can be fixed.
class CalculatorNotifier extends Notifier<CalculatorState> {
  static const CalcEngine _engine = CalcEngine();

  @override
  CalculatorState build() {
    // A new angle mode changes what `sin(30)` is worth, so the live value is
    // worked out again. An answer already shown stays as it was computed.
    ref.listen(angleModeProvider, (_, _) {
      if (state.showsResult) return;
      final buffer = state.buffer;
      state = CalculatorState(buffer: buffer, value: _valueOf(buffer));
    });
    return const CalculatorState();
  }

  /// Handles one key press.
  void press(CalculatorKey key) {
    switch (key) {
      case CalculatorKey.equals:
        _evaluate();
      case CalculatorKey.allClear:
        state = const CalculatorState();
      case CalculatorKey.backspace:
        if (state.showsResult) {
          state = const CalculatorState();
        } else {
          _edit(state.buffer, (buffer) => buffer.backspace());
        }
      case CalculatorKey.add ||
          CalculatorKey.subtract ||
          CalculatorKey.multiply ||
          CalculatorKey.divide ||
          CalculatorKey.power ||
          CalculatorKey.factorial ||
          CalculatorKey.percent:
        _edit(_continuingBuffer, (buffer) => _apply(buffer, key));
      case _:
        _edit(_freshBuffer, (buffer) => _apply(buffer, key));
    }
  }

  /// Types [text], such as pasted input, key by key, and returns whether it
  /// was typed. [text] must use `.` as its decimal point and have no digit
  /// grouping. Text with anything else in it (other than whitespace) is not
  /// typed at all: skipping characters could change a number, as `1.5e12`
  /// would become `1.512`.
  bool typeText(String text) {
    final keys = <CalculatorKey>[];
    for (final char in text.split('')) {
      if (char.trim().isEmpty) continue;
      final key = _keyForCharacter[char];
      if (key == null) return false;
      keys.add(key);
    }
    keys.forEach(press);
    return keys.isNotEmpty;
  }

  /// Moves the cursor [delta] units, while typing.
  void moveCursor(int delta) => setCursor(state.buffer.cursor + delta);

  /// Puts the cursor before unit [index], while typing.
  void setCursor(int index) {
    if (state.showsResult) return;
    final buffer = state.buffer.withCursor(index);
    if (buffer != state.buffer) {
      state = CalculatorState(
        buffer: buffer,
        value: state.value,
        error: state.error,
      );
    }
  }

  /// MR: inserts the memory at the cursor (a new expression after `=`).
  void memoryRecall() {
    final memory = ref.read(memoryProvider);
    if (memory == null) return;
    _edit(_freshBuffer, (buffer) => buffer.insertValue(memory));
  }

  /// Reuses a history entry: inserts its exact result at the cursor (a new
  /// expression after `=`), the same way MR inserts the memory.
  void useHistoryResult(CalcValue result) =>
      _edit(_freshBuffer, (buffer) => buffer.insertValue(result));

  /// MC: empties the memory.
  Future<void> memoryClear() => ref.read(memoryProvider.notifier).clear();

  /// M+: adds the current value to the memory.
  Future<void> memoryAdd() => _withCurrentValue(
    (value) => ref.read(memoryProvider.notifier).add(value),
  );

  /// M−: subtracts the current value from the memory.
  Future<void> memorySubtract() => _withCurrentValue(
    (value) => ref.read(memoryProvider.notifier).subtract(value),
  );

  /// MS: stores the current value in the memory.
  Future<void> memoryStore() => _withCurrentValue(
    (value) => ref.read(memoryProvider.notifier).store(value),
  );

  Future<void> _withCurrentValue(
    Future<void> Function(CalcValue value) action,
  ) async {
    final value = state.currentValue;
    if (value != null) await action(value);
  }

  /// The buffer a new input starts from: empty after `=`.
  ExpressionBuffer get _freshBuffer =>
      state.showsResult ? ExpressionBuffer.empty : state.buffer;

  /// The buffer an operator continues from: the exact answer after `=`.
  ExpressionBuffer get _continuingBuffer => switch (state.result) {
    final CalcValue result => ExpressionBuffer.of([ValueUnit(result)]),
    null => state.buffer,
  };

  /// Applies [change] to [start]. An edit the input rules reject changes
  /// nothing, so a stray key doesn't wipe an answer or an error message.
  /// An accepted edit clears both.
  void _edit(
    ExpressionBuffer start,
    ExpressionBuffer Function(ExpressionBuffer) change,
  ) {
    final buffer = change(start);
    if (buffer == start) return;
    state = CalculatorState(buffer: buffer, value: _valueOf(buffer));
  }

  void _evaluate() {
    if (state.showsResult || state.buffer.isEmpty) return;
    switch (_evaluateBuffer(state.buffer)) {
      case CalcSuccess(:final value):
        final evaluatedExpression = state.buffer.withBracketsClosed;
        state = CalculatorState(
          result: value,
          evaluatedExpression: evaluatedExpression,
        );
        unawaited(
          ref
              .read(historyProvider.notifier)
              .add(
                expression: evaluatedExpression.toCanonicalText(),
                result: value,
                mode: ref.read(currentModeProvider),
              ),
        );
      case CalcFailure(error: CalcError.empty):
        return;
      case CalcFailure(:final error):
        state = CalculatorState(
          buffer: state.buffer,
          value: state.value,
          error: error,
        );
    }
  }

  CalcValue? _valueOf(ExpressionBuffer buffer) {
    if (buffer.isEmpty) return null;
    return switch (_evaluateBuffer(buffer)) {
      CalcSuccess(:final value) => value,
      CalcFailure() => null,
    };
  }

  /// Evaluates [buffer] with its open brackets closed. When closing them
  /// makes an unfinished expression invalid (`(5+` becomes `(5+)`), the
  /// failure is reported as incomplete, which is what it is.
  CalcResult _evaluateBuffer(ExpressionBuffer buffer) {
    final closed = _evaluateUnits(buffer.withBracketsClosed);
    if (closed case CalcFailure(error: CalcError.syntax)
        when buffer.openBrackets > 0) {
      final open = _evaluateUnits(buffer);
      if (open case CalcFailure(error: CalcError.incomplete)) return open;
    }
    return closed;
  }

  CalcResult _evaluateUnits(ExpressionBuffer buffer) {
    final input = buffer.toEngineInput();
    return _engine.evaluate(
      input.expression,
      variables: input.variables,
      angleMode: ref.read(angleModeProvider),
    );
  }

  static ExpressionBuffer _apply(ExpressionBuffer buffer, CalculatorKey key) {
    if (key.digitValue case final int digit) {
      return buffer.insertDigit('$digit');
    }
    return switch (key) {
      CalculatorKey.decimalPoint => buffer.insertDecimalPoint(),
      CalculatorKey.add => buffer.insertOperator(CalculatorSymbols.plus),
      CalculatorKey.subtract => buffer.insertOperator(CalculatorSymbols.minus),
      CalculatorKey.multiply => buffer.insertOperator(CalculatorSymbols.times),
      CalculatorKey.divide => buffer.insertOperator(CalculatorSymbols.divide),
      CalculatorKey.percent => buffer.insertPercent(),
      CalculatorKey.power => buffer.insertOperator(CalculatorSymbols.power),
      CalculatorKey.factorial => buffer.insertFactorial(),
      CalculatorKey.pi => buffer.insertConstant(CalculatorSymbols.pi),
      CalculatorKey.euler => buffer.insertConstant(CalculatorSymbols.euler),
      _ when key.function != null => buffer.insertFunction(key.function!),
      CalculatorKey.brackets => buffer.insertBracket(),
      CalculatorKey.openBracket => buffer.insertOpenBracket(),
      CalculatorKey.closeBracket => buffer.insertCloseBracket(),
      _ => buffer,
    };
  }

  static final Map<String, CalculatorKey> _keyForCharacter = {
    for (var digit = 0; digit <= 9; digit++)
      '$digit': CalculatorKey.digit(digit),
    '.': CalculatorKey.decimalPoint,
    '+': CalculatorKey.add,
    '-': CalculatorKey.subtract,
    '−': CalculatorKey.subtract,
    '*': CalculatorKey.multiply,
    '×': CalculatorKey.multiply,
    'x': CalculatorKey.multiply,
    'X': CalculatorKey.multiply,
    '/': CalculatorKey.divide,
    '÷': CalculatorKey.divide,
    '%': CalculatorKey.percent,
    '^': CalculatorKey.power,
    '!': CalculatorKey.factorial,
    'π': CalculatorKey.pi,
    '(': CalculatorKey.openBracket,
    ')': CalculatorKey.closeBracket,
    '=': CalculatorKey.equals,
  };
}
