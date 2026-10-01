import 'package:calc_engine/calc_engine.dart';

/// A binary operation waiting for its right operand.
final class PendingOperation {
  /// Creates a pending [operation] with [left] (a pattern) already entered.
  const PendingOperation(this.left, this.operation);

  /// The left operand's bits.
  final BigInt left;

  /// What will be done once the right operand is known.
  final ProgrammerOperation operation;

  @override
  bool operator ==(Object other) =>
      other is PendingOperation &&
      other.left == left &&
      other.operation == operation;

  @override
  int get hashCode => Object.hash(left, operation);
}

/// Programmer mode's whole input state, and every key's effect on it
/// (DEC-054). Immutable: each method returns the next session.
///
/// **Value model.** [current] is a *pattern*: the bits of the number shown,
/// in `[0, 2^bits)` (see `ProgrammerWord`). All four base readouts are
/// derived from it; typing never keeps a separate digit string, so leading
/// zeros cannot exist.
///
/// **Execution model: immediate, left to right, no precedence.** Pressing a
/// second operator first finishes the pending one, so `2 + 3 × 4 =` is 20,
/// and `1 << 4 + 1 =` is 17. (Basic and Scientific mode use precedence; a
/// pure bit calculator keeps to the order the keys were pressed.)
///
/// **Two flags that are easy to confuse:**
/// - [replaceOnType]: the next digit starts a new number instead of
///   extending [current] (after `=`, an operator, a unary key, or a change
///   of base, word size or signedness).
/// - [operandReady]: [current] is a right operand rather than just the
///   echoed left operand. Pressing an operator while [pending] and
///   [operandReady] finishes the pending operation; with [pending] but not
///   [operandReady] it merely replaces the operator. A change of base, word
///   size or signedness never touches it, so `5 + 3`, tap HEX, `×` still
///   evaluates `5 + 3` first.
final class ProgrammerSession {
  const ProgrammerSession._({
    required this.base,
    required this.word,
    required this.current,
    required this.negativeEntry,
    required this.replaceOnType,
    required this.operandReady,
    required this.pending,
    required this.overflow,
    required this.error,
  });

  /// The initial session: zero, in [base] and [word].
  ///
  /// The defaults are decimal, 32 bits, signed.
  factory ProgrammerSession.initial({
    ProgrammerBase base = ProgrammerBase.decimal,
    ProgrammerWord word = const ProgrammerWord(bits: 32, signed: true),
  }) => ProgrammerSession._(
    base: base,
    word: word,
    current: BigInt.zero,
    negativeEntry: false,
    replaceOnType: false,
    operandReady: true,
    pending: null,
    overflow: false,
    error: null,
  );

  static const ProgrammerEngine _engine = ProgrammerEngine();

  /// The base digits are typed in.
  final ProgrammerBase base;

  /// The word size and signedness.
  final ProgrammerWord word;

  /// The bits of the number shown, in `[0, 2^bits)`.
  final BigInt current;

  /// Whether a minus sign has been typed first (signed decimal only). It is
  /// what lets `−` then `0` show "−0" and `−128` be typed.
  final bool negativeEntry;

  /// Whether the next digit starts a new number.
  final bool replaceOnType;

  /// Whether [current] is a right operand (see the class comment).
  final bool operandReady;

  /// The operation waiting for a right operand, if any.
  final PendingOperation? pending;

  /// Whether any step of the current calculation wrapped. It stays until a
  /// new calculation starts or AC.
  final bool overflow;

  /// Why the last key had no result, if it did not. Cleared by the next key.
  final ProgrammerError? error;

  /// The value [current] reads as in [word].
  BigInt get value => word.valueOf(current);

  /// Whether `±` is available: only a signed word has negative values.
  bool get canNegate => word.signed;

  BigInt get _magnitude => negativeEntry ? -value : current;

  /// Whether [digit] can be typed now: valid in [base], and the number would
  /// still fit the word.
  bool canAppend(int digit) {
    if (!base.isValidDigit(digit)) return false;
    final startsNew = replaceOnType;
    final next =
        (startsNew ? BigInt.zero : _magnitude) * BigInt.from(base.radix) +
        BigInt.from(digit);
    return next <=
        word.maxTypedMagnitude(base, negative: !startsNew && negativeEntry);
  }

  ProgrammerSession _copy({
    ProgrammerBase? base,
    ProgrammerWord? word,
    BigInt? current,
    bool? negativeEntry,
    bool? replaceOnType,
    bool? operandReady,
    Object? pending = _unset,
    bool? overflow,
    Object? error = _unset,
  }) => ProgrammerSession._(
    base: base ?? this.base,
    word: word ?? this.word,
    current: current ?? this.current,
    negativeEntry: negativeEntry ?? this.negativeEntry,
    replaceOnType: replaceOnType ?? this.replaceOnType,
    operandReady: operandReady ?? this.operandReady,
    pending: identical(pending, _unset)
        ? this.pending
        : pending as PendingOperation?,
    overflow: overflow ?? this.overflow,
    error: identical(error, _unset) ? this.error : error as ProgrammerError?,
  );

  static const Object _unset = Object();

  /// Types [digit]. Ignored if [canAppend] says no.
  ProgrammerSession typeDigit(int digit) {
    if (!canAppend(digit)) return _copy(error: null);
    final startsNew = replaceOnType;
    final negative = !startsNew && negativeEntry;
    final magnitude =
        (startsNew ? BigInt.zero : _magnitude) * BigInt.from(base.radix) +
        BigInt.from(digit);
    return _copy(
      current: word.patternOf(negative ? -magnitude : magnitude),
      negativeEntry: negative,
      replaceOnType: false,
      operandReady: true,
      // A digit that starts a number with nothing pending begins a new
      // calculation.
      overflow: startsNew && pending == null ? false : overflow,
      error: null,
    );
  }

  /// Removes the last typed digit (or a lone minus sign). Does nothing to a
  /// computed value.
  ProgrammerSession backspace() {
    if (replaceOnType) return _copy(error: null);
    final magnitude = _magnitude;
    if (magnitude == BigInt.zero) {
      return _copy(negativeEntry: false, error: null);
    }
    final next = magnitude ~/ BigInt.from(base.radix);
    return _copy(
      current: word.patternOf(negativeEntry ? -next : next),
      error: null,
    );
  }

  /// AC: back to zero with nothing pending. Keeps the base and word.
  ProgrammerSession clear() =>
      ProgrammerSession.initial(base: base, word: word);

  /// Switches the base [current] is shown and typed in.
  ProgrammerSession setBase(ProgrammerBase newBase) {
    if (newBase == base) return this;
    return _copy(
      base: newBase,
      negativeEntry: false,
      replaceOnType: true,
      error: null,
    );
  }

  /// Switches the word size. The *value* is carried over (a negative signed
  /// value sign-extends; narrowing wraps and flags [overflow] if the value no
  /// longer fits).
  ProgrammerSession setBits(int bits) {
    if (bits == word.bits) return this;
    final newWord = word.copyWith(bits: bits);
    final currentValue = value;
    var lost = !newWord.fits(currentValue);
    PendingOperation? newPending;
    final pending = this.pending;
    if (pending != null) {
      final leftValue = word.valueOf(pending.left);
      lost = lost || !newWord.fits(leftValue);
      newPending = PendingOperation(
        newWord.patternOf(leftValue),
        pending.operation,
      );
    }
    return _copy(
      word: newWord,
      current: newWord.patternOf(currentValue),
      pending: newPending,
      negativeEntry: false,
      replaceOnType: true,
      overflow: overflow || lost,
      error: null,
    );
  }

  /// Switches between signed and unsigned. The *bits* are kept; only how
  /// they read changes (so `FF` in a byte is −1 signed and 255 unsigned).
  ProgrammerSession setSigned({required bool signed}) {
    if (signed == word.signed) return this;
    return _copy(
      word: word.copyWith(signed: signed),
      negativeEntry: false,
      replaceOnType: true,
      error: null,
    );
  }

  /// A binary operator key.
  ProgrammerSession pressOperator(ProgrammerOperation operation) {
    final pending = this.pending;
    if (pending == null) {
      return _copy(
        pending: PendingOperation(current, operation),
        negativeEntry: false,
        replaceOnType: true,
        operandReady: false,
        overflow: false, // a new calculation starts
        error: null,
      );
    }
    if (!operandReady) {
      return _copy(
        pending: PendingOperation(pending.left, operation),
        error: null,
      );
    }
    final result = _engine.apply(
      word,
      pending.operation,
      pending.left,
      current,
    );
    return switch (result) {
      ProgrammerFailure(:final error) => _failed(error),
      ProgrammerSuccess() => _copy(
        current: result.pattern,
        pending: PendingOperation(result.pattern, operation),
        negativeEntry: false,
        replaceOnType: true,
        operandReady: false,
        overflow: overflow || result.overflow,
        error: null,
      ),
    };
  }

  /// `=`: finishes the pending operation with [current] as the right
  /// operand (even if none was typed: `5 + =` is 10). With nothing pending
  /// it only marks [current] as a finished number.
  ProgrammerSession pressEquals() {
    final pending = this.pending;
    if (pending == null) {
      return _copy(
        negativeEntry: false,
        replaceOnType: true,
        operandReady: true,
        error: null,
      );
    }
    final result = _engine.apply(
      word,
      pending.operation,
      pending.left,
      current,
    );
    return switch (result) {
      ProgrammerFailure(:final error) => _failed(error),
      ProgrammerSuccess() => _copy(
        current: result.pattern,
        pending: null,
        negativeEntry: false,
        replaceOnType: true,
        operandReady: true,
        overflow: overflow || result.overflow,
        error: null,
      ),
    };
  }

  /// Bitwise NOT of what is shown.
  ProgrammerSession pressNot() {
    final result = _engine.not(word, current) as ProgrammerSuccess;
    return _copy(
      current: result.pattern,
      negativeEntry: false,
      replaceOnType: true,
      operandReady: true,
      overflow: pending == null ? false : overflow,
      error: null,
    );
  }

  /// `±`: negates what is shown. While a signed decimal number is being
  /// typed it flips the typed sign instead (so `±` then `5` is −5 and typing
  /// can continue). Does nothing in an unsigned word.
  ProgrammerSession pressNegate() {
    if (!canNegate) return _copy(error: null);
    if (replaceOnType &&
        base == ProgrammerBase.decimal &&
        pending != null &&
        !operandReady) {
      // Right after an operator the display only echoes the left operand, so
      // `7 ÷ ± 2` means 7 ÷ −2: start a new, negative, number.
      return _copy(
        current: BigInt.zero,
        negativeEntry: true,
        replaceOnType: false,
        operandReady: true,
        error: null,
      );
    }
    if (!replaceOnType && base == ProgrammerBase.decimal) {
      final magnitude = _magnitude;
      final flipped = !negativeEntry;
      if (magnitude > word.maxTypedMagnitude(base, negative: flipped)) {
        return _copy(error: null); // e.g. a typed −128 cannot become +128
      }
      return _copy(
        current: word.patternOf(flipped ? -magnitude : magnitude),
        negativeEntry: flipped,
        operandReady: true,
        error: null,
      );
    }
    final result = _engine.negate(word, current) as ProgrammerSuccess;
    return _copy(
      current: result.pattern,
      negativeEntry: false,
      replaceOnType: true,
      operandReady: true,
      overflow: (pending == null ? false : overflow) || result.overflow,
      error: null,
    );
  }

  ProgrammerSession _failed(ProgrammerError error) => _copy(
    current: BigInt.zero,
    pending: null,
    negativeEntry: false,
    replaceOnType: true,
    operandReady: true,
    overflow: false,
    error: error,
  );
}
