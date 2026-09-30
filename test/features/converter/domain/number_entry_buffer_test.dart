import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/features/converter/domain/number_entry_buffer.dart';

/// Types [keys] into [start]: digits, `.`, `-` (toggles the sign, allowed
/// unless `blockSign`), `<` (backspace), `C` (clear).
NumberEntryBuffer type(
  String keys, {
  NumberEntryBuffer start = NumberEntryBuffer.empty,
  bool blockSign = false,
}) {
  var buffer = start;
  for (final key in keys.split('')) {
    buffer = switch (key) {
      '.' => buffer.insertDecimalPoint(),
      '-' => buffer.toggleSign(allowed: !blockSign),
      '<' => buffer.backspace(),
      'C' => buffer.clear(),
      _ => buffer.insertDigit(key),
    };
  }
  return buffer;
}

void main() {
  group('digits', () {
    test('types plain digits', () {
      expect(type('123').text, '123');
    });

    test('a lone leading zero is replaced, never followed by a digit', () {
      expect(type('0').text, '0');
      expect(type('00').text, '0');
      expect(type('05').text, '5');
    });

    test('zero after a non-zero digit is kept', () {
      expect(type('10').text, '10');
      expect(type('100').text, '100');
    });

    test('stops at the digit limit', () {
      final full = type('1' * NumberEntryBuffer.maxDigits);
      expect(full.text.length, NumberEntryBuffer.maxDigits);
      expect(type('1', start: full).text, full.text);
    });
  });

  group('decimal point', () {
    test('starts a fraction', () {
      expect(type('.5').text, '0.5');
    });

    test(
      'only one per number: the second "." is ignored, digits keep going',
      () {
        expect(type('1.2.3').text, '1.23');
      },
    );

    test('after a lone leading zero, keeps the zero', () {
      expect(type('0.5').text, '0.5');
    });
  });

  group('sign', () {
    test('toggles a leading minus', () {
      expect(type('5-').text, '-5');
      expect(type('5--').text, '5');
    });

    test('works on an empty buffer, ready for digits', () {
      expect(type('-5').text, '-5');
    });

    test('refused when not allowed, leaving the buffer unchanged', () {
      expect(type('5-', blockSign: true).text, '5');
      expect(type('-5', blockSign: true).text, '5');
    });

    test('the decimal point after a lone sign still keeps it', () {
      expect(type('-.5').text, '-0.5');
    });
  });

  group('backspace and clear', () {
    test('backspace removes the last character', () {
      expect(type('123<').text, '12');
      expect(type('1.5<').text, '1.');
      expect(type('-5<').text, '-');
    });

    test('backspace on empty does nothing', () {
      expect(type('<').text, '');
    });

    test('clear empties the buffer regardless of what was typed', () {
      expect(type('-123.45C').text, '');
    });
  });

  group('isEmpty, isNegative and value', () {
    test('isEmpty is true for nothing typed, or only a lone sign', () {
      expect(NumberEntryBuffer.empty.isEmpty, isTrue);
      expect(type('-').isEmpty, isTrue);
      expect(type('0').isEmpty, isFalse);
    });

    test('isNegative reflects the sign', () {
      expect(type('5').isNegative, isFalse);
      expect(type('-5').isNegative, isTrue);
    });

    test('value parses the typed number, null while empty', () {
      expect(NumberEntryBuffer.empty.value, isNull);
      expect(type('-').value, isNull);
      expect(type('12.5').value, 12.5);
      expect(type('-12.5').value, -12.5);
    });
  });

  test('two buffers with the same text are equal', () {
    expect(type('12.5'), type('12.5'));
    expect(type('12.5').hashCode, type('12.5').hashCode);
    expect(type('12.5'), isNot(type('12.6')));
  });
}
