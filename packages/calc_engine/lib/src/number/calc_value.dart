import 'package:rational/rational.dart';

/// A number the engine calculates with: either an exact fraction, or an
/// approximate (`double`) value for a result that isn't rational.
///
/// The numeric library stays inside this folder, so it can be replaced
/// without touching the rest of the engine or the app (DEC-008). Basic
/// arithmetic (`+ − × ÷ %`), whole-number powers and factorials stay exact;
/// irrational results (most of Phase 5's functions, non-perfect roots,
/// fractional powers) are approximate. Combining an exact value with an
/// approximate one is contagious: the result is approximate.
sealed class CalcValue {
  const CalcValue();

  /// The integer [value], exactly.
  factory CalcValue.fromInt(int value) =>
      _ExactCalcValue(Rational.fromInt(value));

  /// Parses a decimal literal such as `12`, `0.5`, `.5` or `5.`, exactly.
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
    return _ExactCalcValue(
      Rational(BigInt.parse(digits), _ten.pow(fraction.length)),
    );
  }

  /// An approximate value, such as an irrational function result. Not
  /// finite (infinite or NaN) becomes [isTooLarge] rather than a raw
  /// double a caller could show.
  factory CalcValue.approximate(double value) => _ApproximateCalcValue(value);

  /// Zero, exactly.
  static final CalcValue zero = CalcValue.fromInt(0);

  static final RegExp _decimalLiteral = RegExp(r'^(\d*)(?:\.(\d*))?$');
  static final BigInt _ten = BigInt.from(10);

  /// Results at or beyond 10^100 in size are reported as overflow.
  static final Rational _overflowLimit = Rational(_ten.pow(100));
  static const double _doubleOverflowLimit = 1e100;

  /// Whether this is zero.
  bool get isZero;

  /// Whether this is too large to report (10^100 or more in size), or not
  /// finite.
  bool get isTooLarge;

  /// Whether this is an exact fraction, rather than an approximate value.
  bool get isExact => this is _ExactCalcValue;

  /// This value as a `double`, exactly for an approximate value, or by
  /// (possibly lossy) conversion for an exact one.
  double toDouble();

  /// The sum of this and [other]. Approximate if either is.
  CalcValue operator +(CalcValue other) => switch ((this, other)) {
    (final _ExactCalcValue a, final _ExactCalcValue b) => _ExactCalcValue(
      a._value + b._value,
    ),
    _ => _ApproximateCalcValue(toDouble() + other.toDouble()),
  };

  /// The difference of this and [other]. Approximate if either is.
  CalcValue operator -(CalcValue other) => switch ((this, other)) {
    (final _ExactCalcValue a, final _ExactCalcValue b) => _ExactCalcValue(
      a._value - b._value,
    ),
    _ => _ApproximateCalcValue(toDouble() - other.toDouble()),
  };

  /// The product of this and [other]. Approximate if either is.
  CalcValue operator *(CalcValue other) => switch ((this, other)) {
    (final _ExactCalcValue a, final _ExactCalcValue b) => _ExactCalcValue(
      a._value * b._value,
    ),
    _ => _ApproximateCalcValue(toDouble() * other.toDouble()),
  };

  /// The quotient of this and [other]. Approximate if either is.
  ///
  /// Throws an [ArgumentError] if [other] is zero; check [isZero] first.
  CalcValue operator /(CalcValue other) {
    if (other.isZero) throw ArgumentError.value(other, 'other', 'is zero');
    return switch ((this, other)) {
      (final _ExactCalcValue a, final _ExactCalcValue b) => _ExactCalcValue(
        a._value / b._value,
      ),
      _ => _ApproximateCalcValue(toDouble() / other.toDouble()),
    };
  }

  /// This value with its sign flipped.
  CalcValue operator -();

  /// The absolute value.
  CalcValue abs();

  /// Whether this is (exactly, or as a whole-number double) negative.
  bool get isNegative;

  /// A lossless text form for storage, such as `-7/3`, `42` or (for an
  /// approximate value) `~1.4142135623730951`. Read it back with
  /// [tryParseStorage].
  String toStorageString();

  /// Reads a value written by [toStorageString], or returns null if [text]
  /// is not in that form.
  static CalcValue? tryParseStorage(String text) {
    if (text.startsWith('~')) {
      final value = double.tryParse(text.substring(1));
      return value == null || !value.isFinite
          ? null
          : _ApproximateCalcValue(value);
    }
    final match = RegExp(r'^(-?\d+)(?:/(\d+))?$').firstMatch(text);
    if (match == null) return null;
    final denominator = BigInt.parse(match.group(2) ?? '1');
    if (denominator == BigInt.zero) return null;
    return _ExactCalcValue(
      Rational(BigInt.parse(match.group(1)!), denominator),
    );
  }

  /// This value as a locale-neutral decimal string, rounded to
  /// [significantDigits] significant digits (half away from zero).
  ///
  /// The form is `-?digits(.digits)?`, or `-?d(.digits)?e-?digits` in
  /// scientific notation, which is used when the value is 10^[significantDigits]
  /// or more in size, or smaller than 10^-6. Trailing zeros are dropped, and
  /// zero is always `0` (never `-0`).
  ///
  /// With [decimalPlaces], the value is first rounded (half away from zero)
  /// to that many places after the point, then written as above. Only the
  /// fraction is ever rounded, so a whole number is unchanged; there are
  /// still at most [significantDigits] significant digits, and a result that
  /// rounds to zero is `0`. An approximate value is rounded from its
  /// [significantDigits]-digit form (so `0.285` at two places is `0.29`, not
  /// the `0.28` of its binary expansion).
  String toDecimalString({int significantDigits = 12, int? decimalPlaces});

  @override
  bool operator ==(Object other) =>
      other is CalcValue &&
      switch ((this, other)) {
        (final _ExactCalcValue a, final _ExactCalcValue b) =>
          a._value == b._value,
        (final _ApproximateCalcValue a, final _ApproximateCalcValue b) =>
          a._value == b._value,
        _ => false,
      };

  @override
  int get hashCode => toDouble().hashCode;
}

/// An exact fraction. The only place that imports `rational` directly.
final class _ExactCalcValue extends CalcValue {
  const _ExactCalcValue(this._value);

  final Rational _value;

  @override
  bool get isZero => _value == Rational.zero;

  @override
  bool get isTooLarge => _value.abs() >= CalcValue._overflowLimit;

  @override
  bool get isNegative => _value.signum < 0;

  @override
  double toDouble() => _value.toDouble();

  @override
  CalcValue operator -() => _ExactCalcValue(-_value);

  @override
  CalcValue abs() => _ExactCalcValue(_value.abs());

  @override
  String toStorageString() => _value.isInteger
      ? '${_value.numerator}'
      : '${_value.numerator}/${_value.denominator}';

  @override
  String toDecimalString({int significantDigits = 12, int? decimalPlaces}) {
    if (significantDigits < 1) {
      throw RangeError.value(significantDigits, 'significantDigits');
    }
    if (decimalPlaces != null) {
      if (decimalPlaces < 0) {
        throw RangeError.value(decimalPlaces, 'decimalPlaces');
      }
      return _roundedToPlaces(decimalPlaces)
          .toDecimalString(significantDigits: significantDigits);
    }
    if (isZero) return '0';
    final sign = _value.signum < 0 ? '-' : '';
    final numerator = _value.numerator.abs();
    final denominator = _value.denominator;
    final ten = CalcValue._ten;

    // exponent = floor(log10(|value|)), from the digit counts, corrected
    // by at most one.
    var exponent = numerator.toString().length - denominator.toString().length;
    if (exponent >= 0
        ? numerator < denominator * ten.pow(exponent)
        : numerator * ten.pow(-exponent) < denominator) {
      exponent--;
    }

    // The value scaled to exactly [significantDigits] integer digits, rounded
    // half away from zero.
    final shift = significantDigits - 1 - exponent;
    final scaledNumerator = shift >= 0 ? numerator * ten.pow(shift) : numerator;
    final scaledDenominator = shift >= 0
        ? denominator
        : denominator * ten.pow(-shift);
    var digits = scaledNumerator ~/ scaledDenominator;
    final remainder = scaledNumerator - digits * scaledDenominator;
    if (remainder * BigInt.two >= scaledDenominator) digits += BigInt.one;
    if (digits == ten.pow(significantDigits)) {
      digits = ten.pow(significantDigits - 1);
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

  /// This value rounded half away from zero to [places] places.
  _ExactCalcValue _roundedToPlaces(int places) {
    final scale = CalcValue._ten.pow(places);
    final scaled = _value.numerator.abs() * scale;
    final denominator = _value.denominator;
    var rounded = scaled ~/ denominator;
    if ((scaled - rounded * denominator) * BigInt.two >= denominator) {
      rounded += BigInt.one;
    }
    return _ExactCalcValue(
      Rational(_value.signum < 0 ? -rounded : rounded, scale),
    );
  }

  static String _trimTrailingZeros(String digits) =>
      digits.replaceFirst(RegExp(r'0+$'), '');

  /// The underlying exact fraction. Only for other engine code inside
  /// `src/number/` and `src/eval/` that needs exact-only operations
  /// (integer powers, factorial, perfect-root checks).
  Rational get rationalValue => _value;

  @override
  String toString() => 'CalcValue(${toStorageString()})';
}

/// An approximate value: a `double`, never NaN or infinite (those become
/// [isTooLarge] before a `CalcValue` is ever constructed from them).
final class _ApproximateCalcValue extends CalcValue {
  _ApproximateCalcValue(this._value)
    : assert(!_value.isNaN, 'Approximate CalcValue must be finite or ±∞');

  final double _value;

  @override
  bool get isZero => _value == 0;

  @override
  bool get isTooLarge =>
      !_value.isFinite || _value.abs() >= CalcValue._doubleOverflowLimit;

  @override
  bool get isNegative => _value < 0;

  @override
  double toDouble() => _value;

  @override
  CalcValue operator -() => _ApproximateCalcValue(-_value);

  @override
  CalcValue abs() => _ApproximateCalcValue(_value.abs());

  @override
  String toStorageString() => '~$_value';

  @override
  String toDecimalString({int significantDigits = 12, int? decimalPlaces}) {
    if (significantDigits < 1) {
      throw RangeError.value(significantDigits, 'significantDigits');
    }
    if (decimalPlaces != null) {
      if (decimalPlaces < 0) {
        throw RangeError.value(decimalPlaces, 'decimalPlaces');
      }
      // Round the digits that are shown, not the binary expansion behind
      // them: 0.285 is 0.28499999999999998 as a double.
      final shown = Rational.parse(
        toDecimalString(significantDigits: significantDigits),
      );
      return _ExactCalcValue(shown).toDecimalString(
        significantDigits: significantDigits,
        decimalPlaces: decimalPlaces,
      );
    }
    // The evaluator always checks isTooLarge (true for non-finite values)
    // before a result reaches here.
    assert(_value.isFinite, 'toDecimalString on a non-finite CalcValue');
    if (_value == 0) return '0';
    // Reuse the exact formatter: 17 significant digits round-trip any
    // double exactly (IEEE-754 double precision), so converting through a
    // Rational here loses nothing the double didn't already lose.
    final precise = Rational.parse(_value.toStringAsExponential(16));
    return _ExactCalcValue(precise)
        .toDecimalString(significantDigits: significantDigits);
  }

  @override
  String toString() => 'CalcValue(${toStorageString()})';
}

/// Engine-internal helpers for code in `src/eval/` that needs to work with
/// the exact fraction directly (integer powers, factorial, perfect-root
/// checks) or build a value from one.
extension CalcValueInternal on CalcValue {
  /// The exact fraction, or null if this value is approximate.
  Rational? get exactValue {
    final self = this;
    return self is _ExactCalcValue ? self.rationalValue : null;
  }
}

/// Builds an exact [CalcValue] from a [Rational]. Engine-internal.
CalcValue calcValueFromRational(Rational value) => _ExactCalcValue(value);
