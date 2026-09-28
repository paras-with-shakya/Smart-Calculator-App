import 'package:intl/intl.dart';

/// Shows numbers the way a region writes them (DEC-037): its decimal and
/// group separators, and its grouping pattern (for example 12,34,567.89 in
/// India, 1,234,567.89 in the US, 1.234.567,89 in Germany).
///
/// It works on text rather than `double`s, so exact values keep every digit:
/// the engine produces locale-neutral decimal strings, and this class
/// localizes them. Digits stay Latin (0-9).
final class LocalizedNumberFormat {
  const LocalizedNumberFormat._({
    required this.decimalSeparator,
    required this.groupSeparator,
    required this._primaryGroupSize,
    required this._secondaryGroupSize,
  });

  /// The format for [localeName], such as `en_IN` or `de-DE`. Unknown
  /// locales fall back to their language, then to English.
  factory LocalizedNumberFormat(String localeName) {
    final verified =
        Intl.verifiedLocale(
          localeName,
          NumberFormat.localeExists,
          onFailure: (_) => 'en',
        ) ??
        'en';
    final symbols = NumberFormat.decimalPattern(verified).symbols;
    final integerPattern = symbols.DECIMAL_PATTERN.split('.').first;
    final groups = integerPattern.split(',');
    final primary = groups.length > 1 ? groups.last.length : 0;
    final secondary = groups.length > 2
        ? groups[groups.length - 2].length
        : primary;
    return LocalizedNumberFormat._(
      decimalSeparator: symbols.DECIMAL_SEP,
      groupSeparator: symbols.GROUP_SEP,
      primaryGroupSize: primary,
      secondaryGroupSize: secondary,
    );
  }

  /// The minus sign shown in numbers (U+2212, matching the keypad).
  static const String minusSign = '−';

  /// The region's decimal separator, such as `.` or `,`.
  final String decimalSeparator;

  /// The region's group separator, such as `,`, `.` or a narrow space.
  final String groupSeparator;

  /// Digits in the group next to the decimal point (0: no grouping).
  final int _primaryGroupSize;

  /// Digits in every further group (2 in India, otherwise usually 3).
  final int _secondaryGroupSize;

  static const Map<String, String> _superscripts = {
    '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', //
    '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹', '-': '⁻',
  };

  /// Localizes a number as typed: digits with an optional `.` and fraction.
  /// A trailing point is kept (`5.` shows as `5.` while typing).
  String formatTyped(String digits) => formatTypedWithOffsets(digits).text;

  /// [formatTyped], plus where each character of [digits] starts in the
  /// text: `offsets[i]` is the text offset of `digits[i]`, and the last
  /// entry is the text's length. A group separator comes before the offset
  /// of the digit it precedes, so a caret there sits next to the digit.
  ({String text, List<int> offsets}) formatTypedWithOffsets(String digits) {
    final point = digits.indexOf('.');
    final wholeLength = point < 0 ? digits.length : point;
    final text = StringBuffer();
    final offsets = <int>[];
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i < wholeLength && _groupStartsAt(wholeLength - i)) {
        text.write(groupSeparator);
      }
      offsets.add(text.length);
      text.write(digits[i] == '.' ? decimalSeparator : digits[i]);
    }
    offsets.add(text.length);
    return (text: text.toString(), offsets: offsets);
  }

  /// Localizes a canonical decimal string (`-?digits(.digits)?(e-?digits)?`,
  /// as the engine produces). Scientific notation shows as `1.5×10¹²`.
  String formatCanonical(String canonical) {
    final negative = canonical.startsWith('-');
    final unsigned = negative ? canonical.substring(1) : canonical;
    final exponentAt = unsigned.indexOf('e');
    final mantissa = exponentAt < 0
        ? unsigned
        : unsigned.substring(0, exponentAt);
    final exponent = exponentAt < 0 ? null : unsigned.substring(exponentAt + 1);
    final sign = negative ? minusSign : '';
    final number = formatTyped(mantissa);
    if (exponent == null) return '$sign$number';
    final power = exponent.split('').map((char) => _superscripts[char]).join();
    return '$sign$number×10$power';
  }

  /// Converts localized text (such as pasted `12,34,567.5`) back to plain
  /// input: group separators and spaces removed, the decimal separator as
  /// `.`.
  String toPlainInput(String text) => text
      .replaceAll(groupSeparator, '')
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll(decimalSeparator, '.');

  /// Whether a group separator goes before a whole-number digit that has
  /// [digitsAfter] digits (itself included) up to the decimal point.
  bool _groupStartsAt(int digitsAfter) {
    if (_primaryGroupSize == 0) return false;
    if (digitsAfter == _primaryGroupSize) return true;
    return _secondaryGroupSize > 0 &&
        digitsAfter > _primaryGroupSize &&
        (digitsAfter - _primaryGroupSize) % _secondaryGroupSize == 0;
  }
}
