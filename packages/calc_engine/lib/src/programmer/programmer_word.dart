/// The number base a programmer-mode value is typed and shown in.
enum ProgrammerBase {
  /// Base 2.
  binary(2),

  /// Base 8.
  octal(8),

  /// Base 10.
  decimal(10),

  /// Base 16.
  hexadecimal(16);

  const ProgrammerBase(this.radix);

  /// The number of distinct digits: 2, 8, 10 or 16.
  final int radix;

  /// Whether [digit] (0 to 15) is a digit of this base.
  bool isValidDigit(int digit) => digit >= 0 && digit < radix;
}

/// A fixed-width integer type: a word of [bits] bits, [signed] or not.
///
/// Programmer mode's canonical value is a *pattern*: a non-negative integer
/// below 2^[bits] (the bits themselves). [signed] only decides how a pattern
/// reads. A signed word reads a pattern with its top bit set as negative
/// (two's complement); an unsigned word reads every pattern as itself.
final class ProgrammerWord {
  /// Creates a word of [bits] bits (one of [supportedBits]).
  const ProgrammerWord({required this.bits, required this.signed})
    : assert(
        bits == 8 || bits == 16 || bits == 32 || bits == 64,
        'bits must be one of ProgrammerWord.supportedBits',
      );

  /// The supported word sizes.
  static const List<int> supportedBits = [8, 16, 32, 64];

  /// The number of bits.
  final int bits;

  /// Whether the top bit is a sign bit (two's complement).
  final bool signed;

  /// 2^[bits]: the number of distinct patterns.
  BigInt get modulus => BigInt.one << bits;

  /// The pattern with every bit set (2^[bits] − 1).
  BigInt get mask => modulus - BigInt.one;

  BigInt get _signBit => BigInt.one << (bits - 1);

  /// The smallest value: −2^([bits]−1) signed, 0 unsigned.
  BigInt get minValue => signed ? -_signBit : BigInt.zero;

  /// The largest value: 2^([bits]−1) − 1 signed, 2^[bits] − 1 unsigned.
  BigInt get maxValue => signed ? _signBit - BigInt.one : mask;

  /// Whether [value] can be held without wrapping.
  bool fits(BigInt value) => value >= minValue && value <= maxValue;

  /// The pattern holding [value], wrapped modulo 2^[bits] (two's complement
  /// for a negative value). Always in `[0, 2^bits)`.
  BigInt patternOf(BigInt value) => value % modulus;

  /// The value [pattern] reads as. [pattern] must be in `[0, 2^bits)`.
  BigInt valueOf(BigInt pattern) {
    assert(
      pattern >= BigInt.zero && pattern <= mask,
      'A pattern is in [0, 2^bits).',
    );
    return signed && pattern >= _signBit ? pattern - modulus : pattern;
  }

  /// The largest magnitude that may be typed in [base] (with a minus sign
  /// when [negative]).
  ///
  /// A signed decimal entry is a *value*, so its positive limit is the
  /// largest value and its negative limit the smallest one's magnitude
  /// (so every value is typeable, −128 included). Every other entry is a
  /// *pattern* of up to [bits] bits: `FF` in a signed byte is typeable, and
  /// reads as −1.
  BigInt maxTypedMagnitude(ProgrammerBase base, {bool negative = false}) {
    if (signed && base == ProgrammerBase.decimal) {
      return negative ? _signBit : _signBit - BigInt.one;
    }
    return mask;
  }

  /// This word with [bits] and [signed] replaced where given.
  ProgrammerWord copyWith({int? bits, bool? signed}) =>
      ProgrammerWord(bits: bits ?? this.bits, signed: signed ?? this.signed);

  @override
  bool operator ==(Object other) =>
      other is ProgrammerWord && other.bits == bits && other.signed == signed;

  @override
  int get hashCode => Object.hash(bits, signed);

  @override
  String toString() => '${signed ? 'int' : 'uint'}$bits';
}
