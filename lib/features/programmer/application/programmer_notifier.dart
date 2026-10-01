import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/features/programmer/domain/programmer_session.dart';

/// The programmer calculator's state: its own session, not
/// `calculatorProvider` (DEC-013's reason for Basic and Scientific to share
/// state does not apply: the input model is different).
///
/// A plain provider, so the state outlives the screen: rotating the phone
/// (which rebuilds the shell around it) does not reset a calculation.
/// Nothing is persisted.
final NotifierProvider<ProgrammerNotifier, ProgrammerSession>
programmerProvider = NotifierProvider<ProgrammerNotifier, ProgrammerSession>(
  ProgrammerNotifier.new,
);

/// Forwards each key to [ProgrammerSession], which holds every rule.
class ProgrammerNotifier extends Notifier<ProgrammerSession> {
  @override
  ProgrammerSession build() => ProgrammerSession.initial();

  /// Types [digit] (0 to 15).
  void typeDigit(int digit) => state = state.typeDigit(digit);

  /// Removes the last typed digit.
  void backspace() => state = state.backspace();

  /// AC.
  void clear() => state = state.clear();

  /// Selects the base to type and show in.
  void setBase(ProgrammerBase base) => state = state.setBase(base);

  /// Selects the word size, in bits.
  void setBits(int bits) => state = state.setBits(bits);

  /// Selects signed or unsigned.
  void setSigned({required bool signed}) =>
      state = state.setSigned(signed: signed);

  /// A binary operator key.
  void pressOperator(ProgrammerOperation operation) =>
      state = state.pressOperator(operation);

  /// `=`.
  void pressEquals() => state = state.pressEquals();

  /// NOT.
  void pressNot() => state = state.pressNot();

  /// ±.
  void pressNegate() => state = state.pressNegate();
}
