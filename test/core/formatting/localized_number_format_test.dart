import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';

void main() {
  final english = LocalizedNumberFormat('en_US');
  final indian = LocalizedNumberFormat('en_IN');
  final german = LocalizedNumberFormat('de_DE');

  group('separators', () {
    test('follow the region', () {
      expect(english.decimalSeparator, '.');
      expect(english.groupSeparator, ',');
      expect(indian.decimalSeparator, '.');
      expect(indian.groupSeparator, ',');
      expect(german.decimalSeparator, ',');
      expect(german.groupSeparator, '.');
      expect(LocalizedNumberFormat('fr_FR').decimalSeparator, ',');
    });

    test('accept a hyphenated locale name', () {
      expect(LocalizedNumberFormat('de-DE').decimalSeparator, ',');
    });

    test('fall back to the language, then to English', () {
      expect(LocalizedNumberFormat('de_XX').decimalSeparator, ',');
      final unknown = LocalizedNumberFormat('xx_YY');
      expect(unknown.decimalSeparator, '.');
      expect(unknown.groupSeparator, ',');
      expect(unknown.formatTyped('1234567'), '1,234,567');
    });
  });

  group('typed numbers', () {
    const englishCases = {
      '': '',
      '0': '0',
      '123': '123',
      '1234': '1,234',
      '123456': '123,456',
      '1234567': '1,234,567',
      '1234567.89': '1,234,567.89',
      '1234.': '1,234.',
      '0.': '0.',
      '0.000001': '0.000001',
      '1234.56789': '1,234.56789',
    };
    englishCases.forEach((typed, expected) {
      test('en_US: "$typed" → "$expected"', () {
        expect(english.formatTyped(typed), expected);
      });
    });

    const indianCases = {
      '123': '123',
      '1234': '1,234',
      '12345': '12,345',
      '123456': '1,23,456',
      '1234567.89': '12,34,567.89',
      '123456789012345': '12,34,56,78,90,12,345',
    };
    indianCases.forEach((typed, expected) {
      test('en_IN: "$typed" → "$expected"', () {
        expect(indian.formatTyped(typed), expected);
      });
    });

    test('de_DE: swaps the separators', () {
      expect(german.formatTyped('1234567.89'), '1.234.567,89');
      expect(german.formatTyped('5.'), '5,');
    });
  });

  group('canonical values', () {
    const cases = {
      '0': '0',
      '1234.5': '1,234.5',
      '-1234.5': '−1,234.5',
      '0.333333333333': '0.333333333333',
      '1.5e12': '1.5×10¹²',
      '-2e-7': '−2×10⁻⁷',
      '9.99999999999e99': '9.99999999999×10⁹⁹',
    };
    cases.forEach((canonical, expected) {
      test('en_US: "$canonical" → "$expected"', () {
        expect(english.formatCanonical(canonical), expected);
      });
    });

    test('follow the region', () {
      expect(indian.formatCanonical('-1234567.5'), '−12,34,567.5');
      expect(german.formatCanonical('1.5e12'), '1,5×10¹²');
    });
  });

  group('pasted text', () {
    test('loses its grouping and uses a plain point', () {
      expect(indian.toPlainInput('12,34,567.5'), '1234567.5');
      expect(german.toPlainInput('1.234.567,5'), '1234567.5');
      expect(english.toPlainInput(' 1,234 + 5 '), '1234+5');
    });

    test('round-trips what the format shows', () {
      for (final format in [english, indian, german]) {
        expect(
          format.toPlainInput(format.formatTyped('1234567.25')),
          '1234567.25',
        );
      }
    });
  });
}
