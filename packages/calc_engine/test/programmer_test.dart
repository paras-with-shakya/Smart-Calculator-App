import 'dart:math';
import 'dart:typed_data';

import 'package:calc_engine/calc_engine.dart';
import 'package:test/test.dart';

const engine = ProgrammerEngine();

final List<ProgrammerWord> allWords = [
  for (final bits in ProgrammerWord.supportedBits)
    for (final signed in [true, false])
      ProgrammerWord(bits: bits, signed: signed),
];

BigInt b(int v) => BigInt.from(v);

/// A pattern from a hex literal, so tests read like the reference tables.
BigInt hex(String digits) => BigInt.parse(digits, radix: 16);

ProgrammerSuccess ok(ProgrammerResult r) {
  expect(r, isA<ProgrammerSuccess>(), reason: '$r');
  return r as ProgrammerSuccess;
}

ProgrammerSuccess run(
  ProgrammerWord word,
  ProgrammerOperation op,
  BigInt left,
  BigInt right,
) => ok(engine.apply(word, op, left, right));

// ---------------------------------------------------------------------
// The independent oracle.
//
// None of this uses the engine's `% modulus` / `valueOf` arithmetic. Wrapping
// comes from Dart's typed-data lists, whose element stores truncate to the
// element width exactly as hardware does, and the operations themselves are
// Dart's native 64-bit `int` operations.
// ---------------------------------------------------------------------

/// Stores [v] in a one-element typed list of [word]'s width and signedness
/// and reads it back: the hardware wrap of [v] to the word.
int wrapNative(ProgrammerWord word, int v) {
  final list = switch ((word.bits, word.signed)) {
    (8, true) => Int8List(1),
    (8, false) => Uint8List(1),
    (16, true) => Int16List(1),
    (16, false) => Uint16List(1),
    (32, true) => Int32List(1),
    (32, false) => Uint32List(1),
    (64, true) => Int64List(1),
    _ => Uint64List(1),
  };
  list[0] = v;
  return list[0];
}

/// The native `int` a pattern reads as in [word] (for an unsigned 64-bit
/// word the bits of the result are the pattern; the int itself may read
/// negative).
int decodeNative(ProgrammerWord word, BigInt pattern) =>
    wrapNative(word, pattern.toSigned(64).toInt());

/// The pattern holding a native `int` after it is wrapped to [word].
BigInt encodeNative(ProgrammerWord word, int v) =>
    BigInt.from(wrapNative(word, v)).toUnsigned(word.bits);

int minNative(ProgrammerWord word) => word.signed ? -(1 << (word.bits - 1)) : 0;

int maxNative(ProgrammerWord word) =>
    word.signed ? (1 << (word.bits - 1)) - 1 : (1 << word.bits) - 1;

/// Boundary patterns plus seeded random ones.
List<BigInt> samplePatterns(ProgrammerWord word, {int random = 40}) {
  final signBit = BigInt.one << (word.bits - 1);
  final rng = Random(word.bits * 2 + (word.signed ? 1 : 0));
  BigInt randomPattern() {
    var v = BigInt.zero;
    for (var i = 0; i < word.bits; i += 16) {
      v = (v << 16) | BigInt.from(rng.nextInt(1 << 16));
    }
    return v & word.mask;
  }

  return {
    BigInt.zero,
    BigInt.one,
    b(2),
    b(3),
    b(7),
    b(10),
    b(100),
    word.mask,
    word.mask - BigInt.one,
    signBit,
    signBit - BigInt.one,
    signBit + BigInt.one,
    signBit >> 1,
    for (var i = 0; i < random; i++) randomPattern(),
  }.toList();
}

void main() {
  group('ProgrammerBase', () {
    test('radix and valid digits', () {
      expect(ProgrammerBase.binary.radix, 2);
      expect(ProgrammerBase.octal.radix, 8);
      expect(ProgrammerBase.decimal.radix, 10);
      expect(ProgrammerBase.hexadecimal.radix, 16);
      for (final base in ProgrammerBase.values) {
        for (var d = 0; d < 16; d++) {
          expect(base.isValidDigit(d), d < base.radix, reason: '$base $d');
        }
        expect(base.isValidDigit(-1), isFalse);
        expect(base.isValidDigit(16), isFalse);
      }
    });
  });

  group('ProgrammerWord', () {
    test('ranges of every word', () {
      final expected = {
        'int8': ('-128', '127', '255'),
        'uint8': ('0', '255', '255'),
        'int16': ('-32768', '32767', '65535'),
        'uint16': ('0', '65535', '65535'),
        'int32': ('-2147483648', '2147483647', '4294967295'),
        'uint32': ('0', '4294967295', '4294967295'),
        'int64': (
          '-9223372036854775808',
          '9223372036854775807',
          '18446744073709551615',
        ),
        'uint64': ('0', '18446744073709551615', '18446744073709551615'),
      };
      for (final word in allWords) {
        final (min, max, mask) = expected['$word']!;
        expect(word.minValue.toString(), min, reason: '$word min');
        expect(word.maxValue.toString(), max, reason: '$word max');
        expect(word.mask.toString(), mask, reason: '$word mask');
        expect(word.modulus, word.mask + BigInt.one);
      }
    });

    test('fits is exactly the range', () {
      for (final word in allWords) {
        expect(word.fits(word.minValue), isTrue);
        expect(word.fits(word.maxValue), isTrue);
        expect(word.fits(word.minValue - BigInt.one), isFalse);
        expect(word.fits(word.maxValue + BigInt.one), isFalse);
      }
    });

    test(
      'valueOf and patternOf agree with typed data, every 8-bit pattern',
      () {
        for (final word in allWords.where((w) => w.bits == 8)) {
          for (var p = 0; p < 256; p++) {
            final pattern = b(p);
            expect(
              word.valueOf(pattern).toInt(),
              decodeNative(word, pattern),
              reason: '$word $p',
            );
            expect(word.patternOf(word.valueOf(pattern)), pattern);
          }
        }
      },
    );

    test(
      'valueOf and patternOf agree with typed data, every 16-bit pattern',
      () {
        for (final word in allWords.where((w) => w.bits == 16)) {
          for (var p = 0; p < 65536; p++) {
            final pattern = b(p);
            expect(word.valueOf(pattern).toInt(), decodeNative(word, pattern));
          }
        }
      },
    );

    test('valueOf and patternOf agree with typed data, 32/64-bit samples', () {
      for (final word in allWords.where((w) => w.bits >= 32)) {
        for (final pattern in samplePatterns(word, random: 200)) {
          final value = word.valueOf(pattern);
          expect(word.fits(value), isTrue);
          expect(word.patternOf(value), pattern);
          if (!(word.bits == 64 && !word.signed)) {
            expect(value.toInt(), decodeNative(word, pattern));
          }
        }
      }
    });

    test('patternOf wraps any integer, negative included', () {
      const int8 = ProgrammerWord(bits: 8, signed: true);
      expect(int8.patternOf(b(-1)), b(255));
      expect(int8.patternOf(b(-128)), b(128));
      expect(int8.patternOf(b(-129)), b(127));
      expect(int8.patternOf(b(256)), b(0));
      expect(int8.patternOf(b(300)), b(44));
      expect(int8.patternOf(b(-256)), b(0));
      expect(int8.patternOf(b(-257)), b(255));
    });

    test('reference readings', () {
      const int8 = ProgrammerWord(bits: 8, signed: true);
      const uint8 = ProgrammerWord(bits: 8, signed: false);
      expect(int8.valueOf(hex('FF')), b(-1));
      expect(int8.valueOf(hex('80')), b(-128));
      expect(int8.valueOf(hex('7F')), b(127));
      expect(uint8.valueOf(hex('FF')), b(255));
      expect(uint8.valueOf(hex('80')), b(128));
      const int64 = ProgrammerWord(bits: 64, signed: true);
      expect(int64.valueOf(hex('FFFFFFFFFFFFFFFF')), b(-1));
      expect(
        int64.valueOf(hex('8000000000000000')),
        BigInt.parse('-9223372036854775808'),
      );
    });

    test('typed-entry limits', () {
      const int8 = ProgrammerWord(bits: 8, signed: true);
      const uint8 = ProgrammerWord(bits: 8, signed: false);
      // Signed decimal: a value. 127 positive, 128 negative (so -128 types).
      expect(int8.maxTypedMagnitude(ProgrammerBase.decimal), b(127));
      expect(
        int8.maxTypedMagnitude(ProgrammerBase.decimal, negative: true),
        b(128),
      );
      // Everything else: a pattern of up to `bits` bits.
      for (final base in [
        ProgrammerBase.binary,
        ProgrammerBase.octal,
        ProgrammerBase.hexadecimal,
      ]) {
        expect(int8.maxTypedMagnitude(base), b(255));
      }
      expect(uint8.maxTypedMagnitude(ProgrammerBase.decimal), b(255));
      expect(uint8.maxTypedMagnitude(ProgrammerBase.hexadecimal), b(255));
    });

    test('equality and copyWith', () {
      const a = ProgrammerWord(bits: 16, signed: true);
      expect(a, const ProgrammerWord(bits: 16, signed: true));
      expect(a == const ProgrammerWord(bits: 16, signed: false), isFalse);
      expect(
        a.copyWith(bits: 32),
        const ProgrammerWord(bits: 32, signed: true),
      );
      expect(
        a.copyWith(signed: false),
        const ProgrammerWord(bits: 16, signed: false),
      );
      expect(a.toString(), 'int16');
    });
  });

  group('reference values (computed independently, by hand)', () {
    const s8 = ProgrammerWord(bits: 8, signed: true);
    const u8 = ProgrammerWord(bits: 8, signed: false);
    const s16 = ProgrammerWord(bits: 16, signed: true);
    const s32 = ProgrammerWord(bits: 32, signed: true);
    const u32 = ProgrammerWord(bits: 32, signed: false);
    const s64 = ProgrammerWord(bits: 64, signed: true);
    const u64 = ProgrammerWord(bits: 64, signed: false);

    void expectResult(
      ProgrammerWord word,
      ProgrammerOperation op,
      BigInt left,
      BigInt right,
      String pattern, {
      bool overflow = false,
    }) {
      final result = run(word, op, left, right);
      expect(
        (result.pattern, result.overflow),
        (hex(pattern), overflow),
        reason:
            '$word $op ${left.toRadixString(16)} '
            '${right.toRadixString(16)}',
      );
    }

    test('signed byte arithmetic', () {
      expectResult(s8, .add, b(127), b(1), '80', overflow: true); // −128
      expectResult(s8, .subtract, hex('80'), b(1), '7F', overflow: true);
      expectResult(s8, .multiply, hex('80'), hex('FF'), '80', overflow: true);
      expectResult(s8, .divide, hex('80'), hex('FF'), '80', overflow: true);
      expectResult(s8, .add, b(100), b(100), 'C8', overflow: true); // −56
      expectResult(s8, .add, b(100), b(27), '7F');
      expectResult(s8, .add, hex('FF'), b(1), '00'); // −1 + 1
      expectResult(s8, .subtract, b(0), b(1), 'FF'); // 0 − 1 = −1
      expectResult(s8, .multiply, hex('FE'), b(3), 'FA'); // −2 × 3 = −6
      expectResult(s8, .divide, hex('F9'), b(2), 'FD'); // −7 ÷ 2 = −3
      expectResult(s8, .divide, b(7), hex('FE'), 'FD'); // 7 ÷ −2 = −3
      expectResult(s8, .divide, hex('F9'), hex('FE'), '03'); // −7 ÷ −2 = 3
    });

    test('unsigned byte arithmetic', () {
      expectResult(u8, .add, b(255), b(1), '00', overflow: true);
      expectResult(u8, .subtract, b(0), b(1), 'FF', overflow: true);
      expectResult(u8, .multiply, b(16), b(16), '00', overflow: true);
      expectResult(u8, .multiply, b(15), b(17), 'FF');
      expectResult(u8, .divide, b(255), b(2), '7F');
    });

    test('wider words', () {
      expectResult(s16, .subtract, hex('8000'), b(1), '7FFF', overflow: true);
      expectResult(
        s32,
        .add,
        hex('7FFFFFFF'),
        b(1),
        '80000000',
        overflow: true,
      );
      expectResult(
        u32,
        .add,
        hex('FFFFFFFF'),
        b(1),
        '00000000',
        overflow: true,
      );
      expectResult(u32, .multiply, b(65536), b(65536), '0', overflow: true);
      expectResult(
        s64,
        .add,
        hex('7FFFFFFFFFFFFFFF'),
        b(1),
        '8000000000000000',
        overflow: true,
      );
      expectResult(
        s64,
        .divide,
        hex('8000000000000000'),
        hex('FFFFFFFFFFFFFFFF'),
        '8000000000000000',
        overflow: true,
      );
      expectResult(
        u64,
        .add,
        hex('FFFFFFFFFFFFFFFF'),
        b(1),
        '0',
        overflow: true,
      );
      expectResult(
        u64,
        .multiply,
        hex('100000000'),
        hex('100000000'),
        '0',
        overflow: true,
      );
      expectResult(
        u64,
        .divide,
        hex('FFFFFFFFFFFFFFFF'),
        b(2),
        '7FFFFFFFFFFFFFFF',
      );
    });

    test('negate', () {
      ProgrammerSuccess neg(ProgrammerWord w, String p) =>
          ok(engine.negate(w, hex(p)));
      expect(neg(s8, '05'), ProgrammerSuccess(hex('FB')));
      expect(neg(s8, 'FB'), ProgrammerSuccess(hex('05')));
      expect(neg(s8, '00'), ProgrammerSuccess(hex('00')));
      expect(neg(s8, '80'), ProgrammerSuccess(hex('80'), overflow: true));
      expect(neg(u8, '01'), ProgrammerSuccess(hex('FF'), overflow: true));
      expect(neg(u8, '00'), ProgrammerSuccess(hex('00')));
      expect(
        neg(s64, '8000000000000000'),
        ProgrammerSuccess(hex('8000000000000000'), overflow: true),
      );
    });

    test('bitwise', () {
      expectResult(u8, .and, hex('F0'), hex('3C'), '30');
      expectResult(u8, .or, hex('F0'), hex('3C'), 'FC');
      expectResult(u8, .xor, hex('F0'), hex('3C'), 'CC');
      expectResult(s8, .and, hex('FF'), hex('80'), '80');
      expectResult(s8, .xor, hex('FF'), hex('FF'), '00');
      ProgrammerSuccess not(ProgrammerWord w, String p) =>
          ok(engine.not(w, hex(p)));
      expect(not(u8, '0F'), ProgrammerSuccess(hex('F0')));
      expect(not(s8, '0F'), ProgrammerSuccess(hex('F0'))); // −16
      expect(not(u8, '00'), ProgrammerSuccess(hex('FF')));
      expect(not(s8, '00'), ProgrammerSuccess(hex('FF'))); // −1
      expect(not(s8, 'FF'), ProgrammerSuccess(hex('00')));
      expect(not(s16, '1234'), ProgrammerSuccess(hex('EDCB')));
      expect(not(u64, '0'), ProgrammerSuccess(hex('FFFFFFFFFFFFFFFF')));
    });

    test('shifts', () {
      // Left: bits shifted out are lost, never an overflow flag.
      expectResult(s8, .shiftLeft, b(1), b(7), '80');
      expectResult(s8, .shiftLeft, hex('FF'), b(7), '80');
      expectResult(s8, .shiftLeft, hex('FF'), b(1), 'FE');
      expectResult(s8, .shiftLeft, hex('81'), b(1), '02');
      expectResult(u8, .shiftLeft, b(1), b(8), '00');
      expectResult(s32, .shiftLeft, b(1), b(31), '80000000');
      expectResult(s64, .shiftLeft, b(1), b(63), '8000000000000000');
      // Right: arithmetic when signed, logical when unsigned.
      expectResult(s8, .shiftRight, hex('80'), b(1), 'C0'); // −128 >> 1 = −64
      expectResult(u8, .shiftRight, hex('80'), b(1), '40');
      expectResult(s8, .shiftRight, hex('F9'), b(1), 'FC'); // −7 >> 1 = −4
      expectResult(s8, .shiftRight, b(0x40), b(1), '20');
      expectResult(s8, .shiftRight, hex('80'), b(7), 'FF');
      expectResult(u8, .shiftRight, hex('80'), b(7), '01');
      expectResult(u64, .shiftRight, hex('FFFFFFFFFFFFFFFF'), b(63), '1');
      expectResult(
        s64,
        .shiftRight,
        hex('FFFFFFFFFFFFFFFF'),
        b(63),
        'FFFFFFFFFFFFFFFF',
      );
      // Shift by zero changes nothing.
      expectResult(s8, .shiftLeft, hex('A5'), b(0), 'A5');
      expectResult(s8, .shiftRight, hex('A5'), b(0), 'A5');
    });

    test('shifts saturate at the word size', () {
      expectResult(s8, .shiftLeft, hex('FF'), b(8), '00');
      expectResult(s8, .shiftLeft, hex('FF'), b(200), '00');
      expectResult(u8, .shiftRight, hex('FF'), b(8), '00');
      expectResult(s8, .shiftRight, hex('80'), b(8), 'FF'); // negative: −1
      expectResult(s8, .shiftRight, hex('7F'), b(8), '00'); // positive: 0
      expectResult(s8, .shiftRight, hex('80'), b(255), 'FF');
    });

    test('a huge shift count neither crashes nor exhausts memory', () {
      for (final (word, count) in [
        (s32, BigInt.one << 31),
        (s32, hex('FFFFFFFF')),
        (s64, BigInt.one << 40),
        (s64, BigInt.one << 63),
        (u64, hex('FFFFFFFFFFFFFFFF')),
      ]) {
        final left = run(word, .shiftLeft, word.mask, count);
        expect(left.pattern, BigInt.zero, reason: '$word << $count');
        final right = run(word, .shiftRight, word.mask, count);
        expect(
          right.pattern,
          word.signed ? word.mask : BigInt.zero,
          reason: '$word >> $count',
        );
      }
    });

    test('truncating division is not an arithmetic shift', () {
      // −7 ÷ 2 truncates toward zero (−3); −7 >> 1 floors (−4).
      expectResult(s8, .divide, hex('F9'), b(2), 'FD');
      expectResult(s8, .shiftRight, hex('F9'), b(1), 'FC');
    });

    test('division by zero is a failure, for every word', () {
      for (final word in allWords) {
        expect(
          engine.apply(word, .divide, b(5), BigInt.zero),
          const ProgrammerFailure(ProgrammerError.divisionByZero),
        );
        expect(
          engine.apply(word, .divide, BigInt.zero, BigInt.zero),
          const ProgrammerFailure(ProgrammerError.divisionByZero),
        );
        expect(run(word, .divide, BigInt.zero, b(3)).pattern, BigInt.zero);
      }
    });
  });

  group('against typed data (the independent oracle)', () {
    // Every operation, every word, boundary and random patterns; the 8-bit
    // words exhaustively.
    List<(BigInt, BigInt)> pairs(ProgrammerWord word) {
      if (word.bits == 8) {
        return [
          for (var x = 0; x < 256; x++)
            for (var y = 0; y < 256; y++) (b(x), b(y)),
        ];
      }
      final samples = samplePatterns(word);
      return [
        for (final x in samples)
          for (final y in samples) (x, y),
      ];
    }

    final wrapping = {
      ProgrammerOperation.add: (int x, int y) => x + y,
      ProgrammerOperation.subtract: (int x, int y) => x - y,
      ProgrammerOperation.multiply: (int x, int y) => x * y,
    };

    for (final word in allWords) {
      test('$word add, subtract, multiply: wrapped results', () {
        for (final (x, y) in pairs(word)) {
          final nx = decodeNative(word, x);
          final ny = decodeNative(word, y);
          for (final entry in wrapping.entries) {
            final result = run(word, entry.key, x, y);
            expect(
              result.pattern,
              encodeNative(word, entry.value(nx, ny)),
              reason:
                  '$word ${entry.key} ${x.toRadixString(16)} '
                  '${y.toRadixString(16)}',
            );
          }
        }
      });

      test('$word bitwise AND, OR, XOR, NOT, negate', () {
        for (final (x, y) in pairs(word)) {
          final nx = decodeNative(word, x);
          final ny = decodeNative(word, y);
          expect(run(word, .and, x, y).pattern, encodeNative(word, nx & ny));
          expect(run(word, .or, x, y).pattern, encodeNative(word, nx | ny));
          expect(run(word, .xor, x, y).pattern, encodeNative(word, nx ^ ny));
        }
        for (final x in samplePatterns(word, random: 200)) {
          final nx = decodeNative(word, x);
          expect(ok(engine.not(word, x)).pattern, encodeNative(word, ~nx));
          expect(ok(engine.not(word, x)).overflow, isFalse);
          expect(ok(engine.negate(word, x)).pattern, encodeNative(word, -nx));
        }
      });

      test('$word shifts, counts 0..70', () {
        final patterns = word.bits == 8
            ? [for (var x = 0; x < 256; x++) b(x)]
            : samplePatterns(word, random: 60);
        for (final x in patterns) {
          final nx = decodeNative(word, x);
          for (var n = 0; n <= 70; n++) {
            final clamped = min(n, 64);
            expect(
              run(word, .shiftLeft, x, b(n)).pattern,
              encodeNative(word, nx << clamped),
              reason: '$word ${x.toRadixString(16)} << $n',
            );
            expect(
              run(word, .shiftRight, x, b(n)).pattern,
              encodeNative(word, word.signed ? nx >> clamped : nx >>> clamped),
              reason: '$word ${x.toRadixString(16)} >> $n',
            );
            expect(run(word, .shiftLeft, x, b(n)).overflow, isFalse);
            expect(run(word, .shiftRight, x, b(n)).overflow, isFalse);
          }
        }
      });

      if (!(word.bits == 64 && !word.signed)) {
        test('$word divide: truncated toward zero', () {
          for (final (x, y) in pairs(word)) {
            final nx = decodeNative(word, x);
            final ny = decodeNative(word, y);
            final result = engine.apply(word, .divide, x, y);
            if (ny == 0) {
              expect(result, isA<ProgrammerFailure>());
            } else {
              // Dart's native `~/` truncates toward zero; the signed
              // minimum ~/ -1 wraps to itself on the VM.
              expect(
                ok(result).pattern,
                encodeNative(word, nx ~/ ny),
                reason: '$word ${x.toRadixString(16)} ÷ ${y.toRadixString(16)}',
              );
            }
          }
        });
      }

      test('$word overflow flags match an independent exact calculation', () {
        for (final (x, y) in pairs(word)) {
          final nx = decodeNative(word, x);
          final ny = decodeNative(word, y);
          final reason = '$word ${x.toRadixString(16)} ${y.toRadixString(16)}';
          bool? flagAdd, flagSub, flagMul;
          if (word.bits <= 32) {
            final lo = minNative(word);
            final hi = maxNative(word);
            bool outside(int v) => v < lo || v > hi;
            flagAdd = outside(nx + ny);
            flagSub = outside(nx - ny);
            // The product can pass 2^63, so compare as doubles: exact below
            // 2^53 and nowhere near a boundary above it.
            final product = nx.toDouble() * ny.toDouble();
            flagMul = product < lo || product > hi;
          } else if (word.signed) {
            // Two's complement overflow identities on native int64.
            final sum = nx + ny;
            flagAdd = ((nx ^ sum) & (ny ^ sum)) < 0;
            final diff = nx - ny;
            flagSub = ((nx ^ ny) & (nx ^ diff)) < 0;
            final prod = nx * ny;
            const min64 = -9223372036854775808;
            flagMul =
                nx != 0 && ((prod ~/ nx != ny) || (nx == -1 && ny == min64));
          } else {
            // Unsigned 64-bit: compare as unsigned by flipping the top bit.
            const flip = -9223372036854775808;
            final sum = nx + ny;
            flagAdd = (sum ^ flip) < (nx ^ flip);
            flagSub = (nx ^ flip) < (ny ^ flip);
            // (no independent unsigned 64-bit multiply oracle; covered by
            // the reference values above)
          }
          expect(run(word, .add, x, y).overflow, flagAdd, reason: '+ $reason');
          expect(
            run(word, .subtract, x, y).overflow,
            flagSub,
            reason: '- $reason',
          );
          if (flagMul != null) {
            expect(
              run(word, .multiply, x, y).overflow,
              flagMul,
              reason: '* $reason',
            );
          }
        }
      });
    }
  });
}
