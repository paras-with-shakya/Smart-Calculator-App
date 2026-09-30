/// A plain (optionally negative) decimal number being typed.
///
/// This is deliberately much simpler than the calculator's
/// `ExpressionBuffer`: there is no grammar here beyond "one number" — no
/// operators, brackets or percent, and so no cursor to move either. Typing
/// always happens at the end; backspace always removes the last
/// character. The only rules are the ones a single number needs: no
/// leading zeros, at most one decimal point, and a digit limit.
final class NumberEntryBuffer {
  const NumberEntryBuffer._(this.text);

  /// The empty buffer.
  static const NumberEntryBuffer empty = NumberEntryBuffer._('');

  /// The most digits this may hold, matching the calculator's own limit
  /// (`ExpressionBuffer.maxDigitsPerNumber`).
  static const int maxDigits = 15;

  /// The text typed so far, such as `"-12.5"`. Empty means nothing typed.
  final String text;

  /// Whether nothing meaningful has been typed (empty, or only a lone
  /// `-`).
  bool get isEmpty => text.isEmpty || text == '-';

  /// Whether a minus sign has been typed.
  bool get isNegative => text.startsWith('-');

  /// The typed value, or null while [isEmpty].
  double? get value => isEmpty ? null : double.tryParse(text);

  /// Types [digit] (0-9).
  NumberEntryBuffer insertDigit(String digit) {
    assert(RegExp(r'^\d$').hasMatch(digit), 'Not a digit: $digit');
    final digitCount = text.replaceAll(RegExp('[^0-9]'), '').length;
    if (digitCount >= maxDigits) return this;
    final unsigned = isNegative ? text.substring(1) : text;
    if (unsigned == '0') {
      // A lone leading zero is replaced, never followed by another digit.
      return digit == '0' ? this : _replace('${isNegative ? '-' : ''}$digit');
    }
    return _replace('$text$digit');
  }

  /// Types the decimal point. Refused if the number already has one.
  NumberEntryBuffer insertDecimalPoint() {
    if (text.contains('.')) return this;
    return _replace(isEmpty ? '${text}0.' : '$text.');
  }

  /// Toggles the leading minus sign. Refused (returns the same buffer)
  /// when [allowed] is false. Callers check
  /// `ConversionCategory.allowsNegative` before offering a sign key at
  /// all, but the buffer enforces it too, so a category that disallows
  /// negative amounts can never end up with one no matter how it's driven.
  NumberEntryBuffer toggleSign({required bool allowed}) {
    if (!allowed) return this;
    return _replace(isNegative ? text.substring(1) : '-$text');
  }

  /// Removes the last typed character.
  NumberEntryBuffer backspace() =>
      text.isEmpty ? this : _replace(text.substring(0, text.length - 1));

  /// Clears everything.
  NumberEntryBuffer clear() => empty;

  NumberEntryBuffer _replace(String newText) => NumberEntryBuffer._(newText);

  @override
  bool operator ==(Object other) =>
      other is NumberEntryBuffer && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'NumberEntryBuffer($text)';
}
