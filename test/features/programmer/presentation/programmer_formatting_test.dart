import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/features/programmer/domain/programmer_session.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_formatting.dart';

BigInt hex(String digits) => BigInt.parse(digits, radix: 16);

void main() {
  group('groupFromRight', () {
    test('groups from the right', () {
      expect(groupFromRight('1A2B3C', 4), '1A 2B3C');
      expect(groupFromRight('123456', 3), '123 456');
      expect(groupFromRight('12345', 3), '12 345');
      expect(groupFromRight('1', 4), '1');
      expect(groupFromRight('', 4), '');
      expect(groupFromRight('1234', 4), '1234');
      expect(groupFromRight('12345', 4), '1 2345');
    });
  });

  group('bases', () {
    test('hexadecimal is upper case in groups of four', () {
      expect(formatHexadecimal(BigInt.zero), '0');
      expect(formatHexadecimal(hex('FF')), 'FF');
      expect(formatHexadecimal(hex('abcdef')), 'AB CDEF');
      expect(formatHexadecimal(hex('FFFFFFFFFFFFFFFF')), 'FFFF FFFF FFFF FFFF');
    });

    test('octal is in groups of three', () {
      expect(formatOctal(BigInt.from(8)), '10');
      expect(formatOctal(BigInt.from(255)), '377');
      expect(formatOctal(BigInt.from(4294967295)), '37 777 777 777');
    });

    test('binary without padding', () {
      expect(formatBinary(BigInt.zero), '0');
      expect(formatBinary(BigInt.from(5)), '101');
      expect(formatBinary(BigInt.from(255)), '1111 1111');
    });
  });

  group('formatBinaryLines', () {
    test('one line of 8 bits, one of 16, two of 32, four of 64', () {
      for (final (bits, lines) in [(8, 1), (16, 1), (32, 2), (64, 4)]) {
        final word = ProgrammerWord(bits: bits, signed: true);
        expect(formatBinaryLines(word, BigInt.zero), hasLength(lines));
      }
    });

    test('is zero-padded to the full word', () {
      const byte = ProgrammerWord(bits: 8, signed: false);
      expect(formatBinaryLines(byte, BigInt.from(5)), ['0000 0101']);
      const word32 = ProgrammerWord(bits: 32, signed: false);
      expect(formatBinaryLines(word32, BigInt.from(5)), [
        '0000 0000 0000 0000',
        '0000 0000 0000 0101',
      ]);
      const word64 = ProgrammerWord(bits: 64, signed: false);
      expect(formatBinaryLines(word64, hex('8000000000000001')), [
        '1000 0000 0000 0000',
        '0000 0000 0000 0000',
        '0000 0000 0000 0000',
        '0000 0000 0000 0001',
      ]);
    });

    test('every line has the same width, so bits line up', () {
      const word = ProgrammerWord(bits: 64, signed: true);
      final lines = formatBinaryLines(word, word.mask);
      expect(lines.map((l) => l.length).toSet(), {19});
    });
  });

  group('formatDecimal', () {
    final india = LocalizedNumberFormat('en_IN');
    final us = LocalizedNumberFormat('en_US');

    ProgrammerSession withValue(int value) {
      var s = ProgrammerSession.initial(
        word: const ProgrammerWord(bits: 64, signed: true),
      );
      for (final digit in value.abs().toString().split('')) {
        s = s.typeDigit(int.parse(digit));
      }
      return value < 0 ? s.pressNegate() : s;
    }

    test('groups the way the device region does', () {
      expect(formatDecimal(india, withValue(1234567)), '12,34,567');
      expect(formatDecimal(us, withValue(1234567)), '1,234,567');
    });

    test('a negative value uses the typographic minus', () {
      expect(formatDecimal(us, withValue(-5)), '−5');
      expect(formatDecimal(us, withValue(-1234)), '−1,234');
    });

    test('keeps every digit of a 64-bit extreme', () {
      var s = ProgrammerSession.initial(
        word: const ProgrammerWord(bits: 64, signed: true),
        base: ProgrammerBase.hexadecimal,
      );
      for (final digit in '8000000000000000'.split('')) {
        s = s.typeDigit(int.parse(digit, radix: 16));
      }
      expect(formatDecimal(us, s), '−9,223,372,036,854,775,808');
      s = s.pressNot();
      expect(formatDecimal(us, s), '9,223,372,036,854,775,807');
    });

    test('a lone minus sign shows -0', () {
      final s = ProgrammerSession.initial().pressNegate();
      expect(formatDecimal(us, s), '−0');
    });
  });

  group('spokenDigits', () {
    test('separates the digits and drops the grouping', () {
      expect(spokenDigits('1010 0101'), '1 0 1 0 0 1 0 1');
      expect(spokenDigits('FF'), 'F F');
      expect(spokenDigits('0'), '0');
    });
  });

  group('formatInBase', () {
    final us = LocalizedNumberFormat('en_US');

    test('shows the pending operand in the base being typed', () {
      var s = ProgrammerSession.initial(
        base: ProgrammerBase.hexadecimal,
        word: const ProgrammerWord(bits: 8, signed: true),
      );
      s = s.typeDigit(15).typeDigit(15);
      expect(formatInBase(us, s, s.current), 'FF');
      expect(
        formatInBase(us, s.setBase(ProgrammerBase.decimal), s.current),
        '−1',
      );
      expect(
        formatInBase(us, s.setBase(ProgrammerBase.binary), s.current),
        '1111 1111',
      );
      expect(
        formatInBase(us, s.setBase(ProgrammerBase.octal), s.current),
        '377',
      );
    });
  });
}
