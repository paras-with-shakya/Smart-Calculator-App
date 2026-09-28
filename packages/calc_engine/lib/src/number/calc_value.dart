import 'package:rational/rational.dart';

/// A number the engine calculates with: an exact fraction.
///
/// The numeric library stays inside this folder, so it can be replaced
/// without touching the rest of the engine or the app (DEC-008). Phase 5
/// adds approximate values for irrational results; the public API stays the
/// same.
final class CalcValue {
  const CalcValue._(this._value);

  /// The integer [value].
  CalcValue.fromInt(int value) : _value = Rational.fromInt(value);

  /// Parses a decimal literal such as `12`, `0.5`, `.5` or `5.`.
  ///
  /// Throws a [FormatException] for anything else: signs, exponents,
  /// separators or a second decimal point.
  factory CalcValue.parse(String literal) {
    final match = _decimalLiteral.firstMatch(literal);
    if (match == null) {
      throw FormatException('Not a decimal literal', literal);
    }
    final whole = match.group(1)!;
    final fraction = match.group(2) ?? '';
    final digits = '$whole$fraction';
    if (digits.isEmpty) throw FormatException('No digits', literal);
    return CalcValue._(
      Rational(BigInt.parse(digits), _ten.pow(fraction.length)),
    );
  }

  /// Zero.
  static final CalcValue zero = CalcValue._(Rational.zero);

  static final RegExp _decimalLiteral = RegExp(r'^(\d*)(?:\.(\d*))?$');
  static final BigInt _ten = BigInt.from(10);

  /// Results at or beyond 10^100 in size are reported as overflow.
  static final Rational _overflowLimit = Rational(_ten.pow(100));

  final Rational _value;

  /// Whether this is zero.
  bool get isZero => _value == Rational.zero;

  /// Whether this is too large to report (10^100 or more in size).
  bool get isTooLarge => _value.abs() >= _overflowLimit;

  /// The sum of this and [other].
  CalcValue operator +(CalcValue other) => CalcValue._(_value + other._value);

  /// The difference of this and [other].
  CalcValue operator -(CalcValue other) => CalcValue._(_value - other._value);

  /// The product of this and [other].
  CalcValue operator *(CalcValue other) => CalcValue._(_value * other._value);

  /// The quotient of this and [other].
  ///
  /// Throws an [ArgumentError] if [other] is zero; check [isZero] first.
  CalcValue operator /(CalcValue other) {
    if (other.isZero) throw ArgumentError.value(other, 'other', 'is zero');
    return CalcValue._(_value / other._value);
  }

  /// This value with its sign flipped.
  CalcValue operator -() => CalcValue._(-_value);

  /// A lossless text form for storage, such as `-7/3` or `42`. Read it back
  /// with [tryParseStorage].
  String toStorageString() => _value.isInteger
      ? '${_value.numerator}'
      : '${_value.numerator}/${_value.denominator}';

  /// Reads a value written by [toStorageString], or returns null if [text]
  /// is not in that form.
  static CalcValue? tryParseStorage(String text) {
    final match = RegExp(r'^(-?\d+)(?:/(\d+))?$').firstMatch(text);
    if (match == null) return null;
    final denominator = BigInt.parse(match.group(2) ?? '1');
    if (denominator == BigInt.zero) return null;
    return CalcValue._(Rational(BigInt.parse(match.group(1)!), denominator));
  }

  /// This value as a locale-neutral decimal string, rounded to
  /// [significantDigits] significant digits (half away from zero).
  ///
  /// The form is `-?digits(.digits)?`, or `-?d(.digits)?e-?digits` in
  /// scientific notation, which is used when the value is 10^[significantDigits]
  /// or more in size, or smaller than 10^-6. Trailing zeros are dropped, and
  /// zero is always `0` (never `-0`).
  String toDecimalString({int significantDigits = 12}) {
    if (significantDigits < 1) {
      throw RangeError.value(significantDigits, 'significantDigits');
    }
    if (isZero) return '0';
    final sign = _value.signum < 0 ? '-' : '';
    final numerator = _value.numerator.abs();
    final denominator = _value.denominator;

    // exponent = floor(log10(|value|)), from the digit counts, corrected
    // by at most one.
    var exponent = numerator.toString().length - denominator.toString().length;
    if (exponent >= 0
        ? numerator < denominator * _ten.pow(exponent)
        : numerator * _ten.pow(-exponent) < denominator) {
      exponent--;
    }

    // The value scaled to exactly [significantDigits] integer digits, rounded
    // half away from zero.
    final shift = significantDigits - 1 - exponent;
    final scaledNumerator = shift >= 0
        ? numerator * _ten.pow(shift)
        : numerator;
    final scaledDenominator = shift >= 0
        ? denominator
        : denominator * _ten.pow(-shift);
    var digits = scaledNumerator ~/ scaledDenominator;
    final remainder = scaledNumerator - digits * scaledDenominator;
    if (remainder * BigInt.two >= scaledDenominator) digits += BigInt.one;
    if (digits == _ten.pow(significantDigits)) {
      digits = _ten.pow(significantDigits - 1);
      exponent++;
    }
    final text = digits.toString();

    if (exponent >= -6 && exponent < significantDigits) {
      if (exponent >= 0) {
        final whole = text.substring(0, exponent + 1);
        final fraction = _trimTrailingZeros(text.substring(exponent + 1));
        return fraction.isEmpty ? '$sign$whole' : '$sign$whole.$fraction';
      }
      final fraction = _trimTrailingZeros('${'0' * (-exponent - 1)}$text');
      return '${sign}0.$fraction';
    }
    final rest = _trimTrailingZeros(text.substring(1));
    final mantissa = rest.isEmpty ? text[0] : '${text[0]}.$rest';
    return '$sign${mantissa}e$exponent';
  }

  static String _trimTrailingZeros(String digits) =>
      digits.replaceFirst(RegExp(r'0+$'), '');

  @override
  bool operator ==(Object other) =>
      other is CalcValue && other._value == _value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'CalcValue(${toStorageString()})';
}
