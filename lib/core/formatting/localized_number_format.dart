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
  String formatTyped(String digits) {
    final point = digits.indexOf('.');
    final whole = point < 0 ? digits : digits.substring(0, point);
    final grouped = _group(whole);
    return point < 0
        ? grouped
        : '$grouped$decimalSeparator${digits.substring(point + 1)}';
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

  String _group(String digits) {
    if (_primaryGroupSize == 0 || digits.length <= _primaryGroupSize) {
      return digits;
    }
    final groups = <String>[
      digits.substring(digits.length - _primaryGroupSize),
    ];
    var end = digits.length - _primaryGroupSize;
    while (end > 0) {
      final start = end - _secondaryGroupSize < 0
          ? 0
          : end - _secondaryGroupSize;
      groups.insert(0, digits.substring(start, end));
      end = start;
    }
    return groups.join(groupSeparator);
  }
}
