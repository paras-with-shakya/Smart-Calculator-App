import 'package:calc_engine/calc_engine.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/features/programmer/domain/programmer_session.dart';

/// How many binary digits one readout line shows: four groups of four.
const int bitsPerBinaryLine = 16;

/// [digits] split into groups of [size] counted from the right, joined by a
/// space: `groupFromRight('1A2B3C', 4)` is `1A 2B3C`.
String groupFromRight(String digits, int size) {
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= size) {
    groups.add(digits.substring(end < size ? 0 : end - size, end));
  }
  return groups.reversed.join(' ');
}

/// [pattern] in hexadecimal, upper case, in groups of four digits.
String formatHexadecimal(BigInt pattern) =>
    groupFromRight(pattern.toRadixString(16).toUpperCase(), 4);

/// [pattern] in octal, in groups of three digits.
String formatOctal(BigInt pattern) =>
    groupFromRight(pattern.toRadixString(8), 3);

/// [pattern] in binary without padding, in groups of four digits.
String formatBinary(BigInt pattern) =>
    groupFromRight(pattern.toRadixString(2), 4);

/// The value of [session] in decimal, grouped the way the device's region
/// groups numbers. `-0` while a minus sign has been typed but no digit yet.
String formatDecimal(LocalizedNumberFormat format, ProgrammerSession session) =>
    session.negativeEntry && session.value == BigInt.zero
    ? '${LocalizedNumberFormat.minusSign}0'
    : format.formatCanonical(session.value.toString());

/// Every bit of [pattern], zero-padded to [word]'s width, as lines of
/// [bitsPerBinaryLine] bits in groups of four (a monospaced font keeps the
/// bits lined up from line to line). One line for 8 and 16 bits, two for 32,
/// four for 64.
List<String> formatBinaryLines(ProgrammerWord word, BigInt pattern) {
  final bits = pattern.toRadixString(2).padLeft(word.bits, '0');
  return [
    for (var i = 0; i < bits.length; i += bitsPerBinaryLine)
      groupFromRight(
        bits.substring(
          i,
          i + bitsPerBinaryLine > bits.length
              ? bits.length
              : i + bitsPerBinaryLine,
        ),
        4,
      ),
  ];
}

/// [text] with a space between every digit, so a screen reader reads the
/// digits one at a time instead of as a number: `1010` reads "1 0 1 0".
String spokenDigits(String text) =>
    text.replaceAll(' ', '').split('').join(' ');

/// How [session] shows [pattern] in its own base, without padding, for the
/// pending operand in the status line.
String formatInBase(
  LocalizedNumberFormat format,
  ProgrammerSession session,
  BigInt pattern,
) => switch (session.base) {
  ProgrammerBase.binary => formatBinary(pattern),
  ProgrammerBase.octal => formatOctal(pattern),
  ProgrammerBase.hexadecimal => formatHexadecimal(pattern),
  ProgrammerBase.decimal => format.formatCanonical(
    session.word.valueOf(pattern).toString(),
  ),
};
