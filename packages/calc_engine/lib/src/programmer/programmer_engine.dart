import 'package:calc_engine/src/programmer/programmer_word.dart';

/// A two-operand programmer-mode operation.
enum ProgrammerOperation {
  /// `+`
  add,

  /// `−`
  subtract,

  /// `×`
  multiply,

  /// `÷`: integer division, truncating toward zero.
  divide,

  /// Bitwise AND.
  and,

  /// Bitwise OR.
  or,

  /// Bitwise XOR.
  xor,

  /// Shift left: the right operand is the shift count.
  shiftLeft,

  /// Shift right: arithmetic (sign-filling) in a signed word, logical in an
  /// unsigned one. The right operand is the shift count.
  shiftRight,
}

/// Why a programmer-mode operation has no result.
enum ProgrammerError {
  /// Division by zero.
  divisionByZero,
}

/// The outcome of a programmer-mode operation: a [ProgrammerSuccess] or a
/// [ProgrammerFailure].
sealed class ProgrammerResult {
  const ProgrammerResult();
}

/// A result pattern, and whether the exact result had to be wrapped.
final class ProgrammerSuccess extends ProgrammerResult {
  /// Creates a success holding [pattern].
  const ProgrammerSuccess(this.pattern, {this.overflow = false});

  /// The result's bits, in `[0, 2^bits)`.
  final BigInt pattern;

  /// Whether the exact mathematical result did not fit the word and was
  /// wrapped modulo 2^bits. Only arithmetic (`+ − × ÷`, negate) overflows;
  /// bitwise operations and shifts never do.
  final bool overflow;

  @override
  bool operator ==(Object other) =>
      other is ProgrammerSuccess &&
      other.pattern == pattern &&
      other.overflow == overflow;

  @override
  int get hashCode => Object.hash(pattern, overflow);

  @override
  String toString() => 'ProgrammerSuccess($pattern, overflow: $overflow)';
}

/// An operation with no result.
final class ProgrammerFailure extends ProgrammerResult {
  /// Creates a failure with [error].
  const ProgrammerFailure(this.error);

  /// What went wrong.
  final ProgrammerError error;

  @override
  bool operator ==(Object other) =>
      other is ProgrammerFailure && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'ProgrammerFailure($error)';
}

/// Programmer mode's integer arithmetic on `BigInt` patterns (DEC-054).
///
/// Every operand and result is a pattern in `[0, 2^bits)` of a
/// [ProgrammerWord]. The conventions, all fixed and tested:
///
/// - **Arithmetic** (`+ − × ÷`, negate) works on the operands' *values*
///   (two's complement when signed) and wraps the exact result modulo
///   2^bits, flagging `overflow` when the exact result did not fit.
/// - **Division** truncates toward zero; the signed minimum divided by −1
///   wraps to the minimum (flagged); a zero divisor is a failure.
/// - **Bitwise** operations work on the patterns and never overflow.
/// - **Shifts** use the right operand as an unsigned count. A count of
///   [ProgrammerWord.bits] or more shifts everything out: 0, or −1 for an
///   arithmetic right shift of a negative value. Shifted-out bits are lost
///   without an overflow flag, exactly as in hardware.
final class ProgrammerEngine {
  /// Creates the engine (it holds no state).
  const ProgrammerEngine();

  /// [left] `op` [right], in [word].
  ProgrammerResult apply(
    ProgrammerWord word,
    ProgrammerOperation op,
    BigInt left,
    BigInt right,
  ) {
    switch (op) {
      case ProgrammerOperation.add:
        return _wrap(word, word.valueOf(left) + word.valueOf(right));
      case ProgrammerOperation.subtract:
        return _wrap(word, word.valueOf(left) - word.valueOf(right));
      case ProgrammerOperation.multiply:
        return _wrap(word, word.valueOf(left) * word.valueOf(right));
      case ProgrammerOperation.divide:
        final divisor = word.valueOf(right);
        if (divisor == BigInt.zero) {
          return const ProgrammerFailure(ProgrammerError.divisionByZero);
        }
        return _wrap(word, word.valueOf(left) ~/ divisor);
      case ProgrammerOperation.and:
        return ProgrammerSuccess(left & right);
      case ProgrammerOperation.or:
        return ProgrammerSuccess(left | right);
      case ProgrammerOperation.xor:
        return ProgrammerSuccess(left ^ right);
      case ProgrammerOperation.shiftLeft:
        final count = _shiftCount(word, right);
        return ProgrammerSuccess(
          count >= word.bits ? BigInt.zero : (left << count) & word.mask,
        );
      case ProgrammerOperation.shiftRight:
        // `value >> bits` is already 0 (or −1 for a negative value), so
        // clamping the count to the word size is all the saturation needed.
        final count = _shiftCount(word, right);
        return ProgrammerSuccess(word.patternOf(word.valueOf(left) >> count));
    }
  }

  /// Bitwise NOT: every bit of [pattern] flipped.
  ProgrammerResult not(ProgrammerWord word, BigInt pattern) =>
      ProgrammerSuccess(pattern ^ word.mask);

  /// Two's complement negation. Overflows (and wraps back to itself) only
  /// for the signed minimum; an unsigned word flags every non-zero input,
  /// since −x is outside an unsigned range.
  ProgrammerResult negate(ProgrammerWord word, BigInt pattern) =>
      _wrap(word, -word.valueOf(pattern));

  ProgrammerResult _wrap(ProgrammerWord word, BigInt exact) =>
      ProgrammerSuccess(word.patternOf(exact), overflow: !word.fits(exact));

  /// [count] clamped to the word size, as an `int` that is safe to shift by.
  ///
  /// Compared as a `BigInt` *before* converting: `BigInt.toInt()` clamps and
  /// a huge shift would exhaust memory.
  int _shiftCount(ProgrammerWord word, BigInt count) =>
      count >= BigInt.from(word.bits) ? word.bits : count.toInt();
}
