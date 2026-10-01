import 'package:calc_engine/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/programmer/domain/programmer_session.dart';

const s8 = ProgrammerWord(bits: 8, signed: true);
const u8 = ProgrammerWord(bits: 8, signed: false);
const s16 = ProgrammerWord(bits: 16, signed: true);

/// Presses keys: `0-9 A-F` digits, `+ - * /` arithmetic, `& | ^` bitwise,
/// `L`/`R` shift left/right, `=`, `~` NOT, `n` negate (±), `<` backspace,
/// `!` AC.
ProgrammerSession press(String keys, ProgrammerSession from) {
  var s = from;
  for (final key in keys.split('')) {
    s = switch (key) {
      '+' => s.pressOperator(.add),
      '-' => s.pressOperator(.subtract),
      '*' => s.pressOperator(.multiply),
      '/' => s.pressOperator(.divide),
      '&' => s.pressOperator(.and),
      '|' => s.pressOperator(.or),
      '^' => s.pressOperator(.xor),
      'L' => s.pressOperator(.shiftLeft),
      'R' => s.pressOperator(.shiftRight),
      '=' => s.pressEquals(),
      '~' => s.pressNot(),
      'n' => s.pressNegate(),
      '<' => s.backspace(),
      '!' => s.clear(),
      ' ' => s,
      _ => s.typeDigit(int.parse(key, radix: 16)),
    };
  }
  return s;
}

ProgrammerSession start({
  ProgrammerBase base = ProgrammerBase.decimal,
  ProgrammerWord word = s8,
}) => ProgrammerSession.initial(base: base, word: word);

int v(ProgrammerSession s) => s.value.toInt();
String h(ProgrammerSession s) => s.current.toRadixString(16).toUpperCase();

void main() {
  group('defaults', () {
    test('decimal, 32 bits, signed, zero', () {
      final s = ProgrammerSession.initial();
      expect(s.base, ProgrammerBase.decimal);
      expect(s.word, const ProgrammerWord(bits: 32, signed: true));
      expect(s.current, BigInt.zero);
      expect(s.pending, isNull);
      expect(s.overflow, isFalse);
      expect(s.error, isNull);
    });
  });

  group('typing', () {
    test('digits build the number; leading zeros vanish', () {
      expect(v(press('123', start())), 123);
      expect(v(press('007', start())), 7);
      expect(v(press('000', start())), 0);
    });

    test('only digits of the base are accepted', () {
      final bin = start(base: ProgrammerBase.binary, word: u8);
      expect(bin.canAppend(0), isTrue);
      expect(bin.canAppend(1), isTrue);
      expect(bin.canAppend(2), isFalse);
      final oct = start(base: ProgrammerBase.octal, word: u8);
      expect(oct.canAppend(7), isTrue);
      expect(oct.canAppend(8), isFalse);
      final dec = start(word: u8);
      expect(dec.canAppend(9), isTrue);
      expect(dec.canAppend(10), isFalse);
      final hex = start(base: ProgrammerBase.hexadecimal, word: u8);
      expect(hex.canAppend(15), isTrue);
      expect(hex.canAppend(16), isFalse);
      expect(press('2', bin).current, BigInt.zero); // ignored
    });

    test('a number that would not fit is ignored', () {
      expect(v(press('256', start(word: u8))), 25);
      expect(v(press('255', start(word: u8))), 255);
      // Signed decimal: a value, so 127 is the largest positive.
      expect(v(press('128', start())), 12);
      expect(v(press('127', start())), 127);
      expect(press('13', start()).canAppend(0), isFalse);
    });

    test('hex and binary are patterns: FF in a signed byte reads as -1', () {
      final s = press('FF', start(base: ProgrammerBase.hexadecimal));
      expect(h(s), 'FF');
      expect(v(s), -1);
      expect(h(press('FFF', start(base: ProgrammerBase.hexadecimal))), 'FF');
      final bin = press('10000001', start(base: ProgrammerBase.binary));
      expect(v(bin), -127);
      expect(h(press('100000011', start(base: ProgrammerBase.binary))), '81');
    });

    test('every representable value can be typed (signed byte, decimal)', () {
      for (var value = -128; value <= 127; value++) {
        final text = value.abs().toString();
        final s = press(value < 0 ? 'n$text' : text, start());
        expect(v(s), value, reason: '$value');
      }
    });

    test('every unsigned byte can be typed in every base', () {
      for (var value = 0; value < 256; value++) {
        for (final (base, radix) in [
          (ProgrammerBase.binary, 2),
          (ProgrammerBase.octal, 8),
          (ProgrammerBase.decimal, 10),
          (ProgrammerBase.hexadecimal, 16),
        ]) {
          final s = press(
            value.toRadixString(radix).toUpperCase(),
            start(base: base, word: u8),
          );
          expect(v(s), value, reason: '$value in base $radix');
        }
      }
    });

    test('a typed negative number can continue and be edited', () {
      final s = press('n12', start());
      expect(v(s), -12);
      expect(s.negativeEntry, isTrue);
      expect(v(press('3', s)), -123);
      expect(v(press('n', s)), 12); // flips back
      expect(v(press('n9', start())), -9);
    });

    test('a negative can reach -128 but not a positive 128', () {
      expect(v(press('n128', start())), -128);
      expect(v(press('n1289', start())), -128); // 1289 does not fit
      final typed = press('n128', start());
      expect(v(press('n', typed)), -128); // -128 -> +128 is not possible
      expect(press('n128', start()).negativeEntry, isTrue);
    });

    test('a lone minus sign shows -0 and the next digit is negative', () {
      final s = press('n', start());
      expect(s.negativeEntry, isTrue);
      expect(v(s), 0);
      expect(v(press('5', s)), -5);
    });

    test('backspace removes a digit, then a lone minus sign', () {
      expect(v(press('123<', start())), 12);
      expect(v(press('1<', start())), 0);
      expect(v(press('<<<', start())), 0);
      final s = press('n12<<', start());
      expect(v(s), 0);
      expect(s.negativeEntry, isTrue);
      expect(press('n12<<<', start()).negativeEntry, isFalse);
      expect(v(press('n12<', start())), -1);
    });

    test('backspace leaves a computed value alone', () {
      final s = press('2+3=<', start());
      expect(v(s), 5);
    });

    test('a typed number after = starts a new number', () {
      expect(v(press('2+3=7', start())), 7);
    });
  });

  group('operators run left to right, with no precedence', () {
    test('2 + 3 x 4 = 20', () => expect(v(press('2+3*4=', start())), 20));
    test('1 << 4 + 1 = 17', () => expect(v(press('1L4+1=', start())), 17));
    test('10 - 4 - 3 = 3', () => expect(v(press('10-4-3=', start())), 3));
    test('a chain shows the running result before =', () {
      final s = press('2+3*', start());
      expect(v(s), 5);
      expect(s.pending!.operation, ProgrammerOperation.multiply);
    });
    test('pressing another operator replaces it', () {
      expect(v(press('5+*3=', start())), 15);
      expect(v(press('5+-*3=', start())), 15);
    });
    test('= repeated does nothing more', () {
      expect(v(press('2+3==', start())), 5);
    });
    test('= with no right operand uses the shown value: 5 + = is 10', () {
      expect(v(press('5+=', start())), 10);
    });
    test('= with nothing pending keeps the value and starts fresh', () {
      final s = press('7=', start());
      expect(v(s), 7);
      expect(v(press('2', s)), 2);
    });
  });

  group('changing base never loses an operand', () {
    test('5 + 3, switch to HEX, x 2 = 16', () {
      var s = press('5+3', start());
      s = s.setBase(ProgrammerBase.hexadecimal);
      s = press('*2=', s);
      expect(v(s), 16);
    });

    test('5 +, switch base, then x only replaces the operator', () {
      var s = press('5+', start());
      s = s.setBase(ProgrammerBase.binary);
      s = press('*', s);
      expect(s.pending!.operation, ProgrammerOperation.multiply);
      expect(v(press('11=', s)), 15); // 5 x 3, typed in binary
    });

    test('5 + NOT x does not drop the NOT result', () {
      var s = press('5+~', start()); // 5 + ~5 = 5 + -6
      s = press('*', s);
      expect(v(s), -1);
      expect(v(press('2=', s)), -2);
    });

    test('the value survives, the next digit starts a new number', () {
      var s = press('255', start(word: u8));
      s = s.setBase(ProgrammerBase.hexadecimal);
      expect(h(s), 'FF');
      expect(v(press('A', s)), 10);
    });

    test('switching to the same base changes nothing', () {
      final s = press('12', start());
      expect(identical(s.setBase(ProgrammerBase.decimal), s), isTrue);
      expect(v(press('3', s.setBase(ProgrammerBase.decimal))), 123);
    });
  });

  group('division', () {
    test('divide by zero is an error, clears the chain, and recovers', () {
      final s = press('5/0=', start());
      expect(s.error, ProgrammerError.divisionByZero);
      expect(s.pending, isNull);
      expect(v(s), 0);
      expect(s.overflow, isFalse);
      final next = press('7', s);
      expect(next.error, isNull);
      expect(v(next), 7);
    });

    test('divide by zero while chaining', () {
      expect(press('5/0+', start()).error, ProgrammerError.divisionByZero);
    });

    test('any key clears the error', () {
      final s = press('5/0=', start());
      expect(s.backspace().error, isNull);
      expect(s.clear().error, isNull);
      expect(s.pressNot().error, isNull);
      expect(s.setBase(ProgrammerBase.binary).error, isNull);
      expect(s.pressOperator(ProgrammerOperation.add).error, isNull);
      expect(s.pressEquals().error, isNull);
    });

    test('truncates toward zero', () {
      expect(v(press('n7/2=', start())), -3);
      expect(v(press('7/n2=', start())), -3);
    });

    test('-128 / -1 wraps and flags overflow', () {
      final s = press('n128/n1=', start());
      expect(v(s), -128);
      expect(s.overflow, isTrue);
    });
  });

  group('overflow', () {
    test('127 + 1 wraps to -128 and flags it', () {
      final s = press('127+1=', start());
      expect(v(s), -128);
      expect(s.overflow, isTrue);
    });

    test('an in-range result does not flag', () {
      expect(press('100+27=', start()).overflow, isFalse);
    });

    test('it is sticky through a chain: 127 + 1 + 1 =', () {
      final s = press('127+1+1=', start());
      expect(v(s), -127);
      expect(s.overflow, isTrue);
    });

    test('it is shown while the chain is pending too', () {
      expect(press('127+1+', start()).overflow, isTrue);
    });

    test('a new calculation clears it', () {
      final flagged = press('127+1=', start());
      expect(press('5', flagged).overflow, isFalse);
      expect(press('+', flagged).overflow, isFalse);
      expect(press('~', flagged).overflow, isFalse);
      expect(flagged.clear().overflow, isFalse);
    });

    test('unsigned wraps too', () {
      final s = press('255+1=', start(word: u8));
      expect(v(s), 0);
      expect(s.overflow, isTrue);
      expect(v(press('0-1=', start(word: u8))), 255);
      expect(press('0-1=', start(word: u8)).overflow, isTrue);
    });

    test('bitwise operations and shifts never flag it', () {
      expect(
        press('FF&80=', start(base: ProgrammerBase.hexadecimal)).overflow,
        isFalse,
      );
      expect(press('1L7=', start()).overflow, isFalse);
      expect(press('~', start()).overflow, isFalse);
    });

    test('negating the signed minimum flags it', () {
      final s = press('n128n', start());
      // Typing a negative number then ± flips the typed sign, and +128 does
      // not fit, so nothing changes; compute the negate on a result instead.
      expect(v(s), -128);
      final computed = press('n128=n', start());
      expect(v(computed), -128);
      expect(computed.overflow, isTrue);
    });
  });

  group('unary keys', () {
    test('NOT flips every bit of the word', () {
      final f = press('F', start(base: ProgrammerBase.hexadecimal, word: u8));
      expect(h(f.pressNot()), 'F0');
      expect(v(press('15~', start())), -16); // signed byte
      expect(v(press('15~', start(word: u8))), 240);
      expect(v(press('~', start())), -1);
    });

    test('NOT applied to a pending operand', () {
      expect(v(press('5&0~=', start())), 5); // 5 AND NOT 0 = 5
    });

    test('NOT twice is the original', () {
      expect(v(press('42~~', start())), 42);
    });

    test('negate typed decimal flips the sign and typing continues', () {
      expect(v(press('5n', start())), -5);
      expect(v(press('5n3', start())), -53);
      expect(v(press('5nn', start())), 5);
    });

    test('negate in hex is two complement of the pattern', () {
      final s = press('5n', start(base: ProgrammerBase.hexadecimal));
      expect(h(s), 'FB');
      expect(v(s), -5);
    });

    test('negate a computed value', () {
      expect(v(press('2+3=n', start())), -5);
      expect(v(press('2+3=nn', start())), 5);
    });

    test('negate is unavailable unsigned', () {
      final s = start(word: u8);
      expect(s.canNegate, isFalse);
      final typed = press('5', s);
      expect(v(typed.pressNegate()), 5);
    });

    test('negate with an operator pending negates the shown operand', () {
      expect(v(press('5+3n=', start())), 2);
    });

    test('right after an operator, negate starts a negative number', () {
      expect(v(press('7/n2=', start())), -3);
      expect(v(press('5*n3=', start())), -15);
      final s = press('5+n', start());
      expect(s.negativeEntry, isTrue);
      expect(s.replaceOnType, isFalse);
      expect(v(s), 0);
    });

    test('after an operator in hex, negate negates the shown operand', () {
      final s = press('5+n', start(base: ProgrammerBase.hexadecimal));
      expect(v(s), -5);
      expect(s.negativeEntry, isFalse);
    });
  });

  group('shifts', () {
    test('left shift keeps the bits that fit', () {
      expect(h(press('1L7=', start())), '80');
      expect(v(press('1L7=', start())), -128);
      expect(h(press('FFL4=', start(base: ProgrammerBase.hexadecimal))), 'F0');
    });

    test('right shift is arithmetic when signed, logical when unsigned', () {
      expect(v(press('80R1=', start(base: ProgrammerBase.hexadecimal))), -64);
      expect(
        v(press('80R1=', start(base: ProgrammerBase.hexadecimal, word: u8))),
        64,
      );
    });

    test('the count is read in the active base', () {
      expect(
        v(
          press(
            '1L10=',
            start(
              base: ProgrammerBase.hexadecimal,
              word: const ProgrammerWord(bits: 32, signed: true),
            ),
          ),
        ),
        65536,
      );
      expect(v(press('1L10=', start())), 0); // 1 << 10 in a byte
    });

    test('a count of the word size or more shifts everything out', () {
      expect(v(press('FFL8=', start(base: ProgrammerBase.hexadecimal))), 0);
      expect(v(press('n1R9=', start())), -1);
      expect(v(press('1R9=', start())), 0);
    });

    test('a negative count reads as its unsigned bit pattern', () {
      // -1 is the pattern FF = 255, so 1 << 255 is 0.
      expect(v(press('1Ln1=', start())), 0);
    });
  });

  group('word size and signedness', () {
    test('narrowing wraps the value and flags it', () {
      final wide = press(
        '300',
        start(word: const ProgrammerWord(bits: 32, signed: true)),
      );
      final narrow = wide.setBits(8);
      expect(v(narrow), 44);
      expect(narrow.overflow, isTrue);
    });

    test('narrowing a value that fits does not flag', () {
      final narrow = press('100', start(word: s16)).setBits(8);
      expect(v(narrow), 100);
      expect(narrow.overflow, isFalse);
    });

    test('widening a negative signed value sign-extends', () {
      final s = press('n1', start()).pressEquals().setBits(16);
      expect(v(s), -1);
      expect(h(s), 'FFFF');
      expect(s.overflow, isFalse);
    });

    test('widening an unsigned value zero-extends', () {
      final s = press('255', start(word: u8)).setBits(16);
      expect(h(s), 'FF');
      expect(v(s), 255);
    });

    test('signedness keeps the bits and changes the reading', () {
      var s = press('255', start(word: u8));
      expect(v(s), 255);
      s = s.setSigned(signed: true);
      expect(h(s), 'FF');
      expect(v(s), -1);
      s = s.setSigned(signed: false);
      expect(v(s), 255);
    });

    test('the order matters: unsigned then widen vs widen then unsigned', () {
      final start1 = press('FF', start(base: ProgrammerBase.hexadecimal));
      expect(v(start1), -1);
      final a = start1.setSigned(signed: false).setBits(16);
      expect(v(a), 255); // 255 carried to 16 bits
      final b = start1.setBits(16).setSigned(signed: false);
      expect(v(b), 65535); // -1 sign-extended, then read unsigned
    });

    test('u8 200 read signed is -56, which widens to FFC8', () {
      final s = press(
        '200',
        start(word: u8),
      ).setSigned(signed: true).setBits(16);
      expect(v(s), -56);
      expect(h(s), 'FFC8');
    });

    test('a pending operand is converted with the value', () {
      var s = press(
        '5+',
        start(word: const ProgrammerWord(bits: 32, signed: true)),
      );
      s = s.setBits(8);
      expect(s.pending!.left, BigInt.from(5));
      expect(v(press('3=', s)), 8);
    });

    test('a pending negative operand sign-extends', () {
      var s = press('n1=+', start());
      s = s.setBits(16);
      expect(s.pending!.left, BigInt.from(0xFFFF));
      expect(v(press('1=', s)), 0);
    });

    test('changing word or sign does not end a pending operation', () {
      var s = press('5+3', start());
      s = s.setBits(16).setSigned(signed: false);
      expect(v(press('*2=', s)), 16);
    });

    test('same size and same signedness change nothing', () {
      final s = press('12', start());
      expect(identical(s.setBits(8), s), isTrue);
      expect(identical(s.setSigned(signed: true), s), isTrue);
    });
  });

  group('AC', () {
    test('clears the value and the chain but keeps base and word', () {
      var s = start(base: ProgrammerBase.hexadecimal, word: s16);
      s = press('FF+1', s);
      final cleared = s.clear();
      expect(cleared.base, ProgrammerBase.hexadecimal);
      expect(cleared.word, s16);
      expect(cleared.current, BigInt.zero);
      expect(cleared.pending, isNull);
      expect(cleared.overflow, isFalse);
      expect(cleared.negativeEntry, isFalse);
    });
  });
}
