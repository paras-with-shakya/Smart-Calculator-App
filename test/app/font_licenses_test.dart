import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/font_licenses.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// The `post` table's `isFixedPitch` field of a TrueType font: non-zero for
/// a monospaced font.
int isFixedPitch(ByteData font) {
  final tableCount = font.getUint16(4);
  for (var i = 0; i < tableCount; i++) {
    final entry = 12 + i * 16;
    final tag = String.fromCharCodes([
      for (var k = 0; k < 4; k++) font.getUint8(entry + k),
    ]);
    if (tag == 'post') return font.getUint32(font.getUint32(entry + 8) + 12);
  }
  fail('no post table');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every Manrope weight is bundled', () async {
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final font = await rootBundle.load('assets/fonts/Manrope-$weight.ttf');
      expect(font.lengthInBytes, greaterThan(0), reason: weight);
    }
  });

  test('every JetBrains Mono weight is bundled, and is monospaced', () async {
    for (final weight in ['Regular', 'Medium', 'SemiBold']) {
      final font = await rootBundle.load(
        'assets/fonts/JetBrainsMono-$weight.ttf',
      );
      expect(font.lengthInBytes, greaterThan(0), reason: weight);
      expect(isFixedPitch(font), isNonZero, reason: '$weight is monospaced');
    }
  });

  test('the readout style uses the bundled monospaced family', () {
    expect(AppTypography.standard.mono.fontFamily, 'JetBrains Mono');
    expect(AppTypography.monoFontFamily, 'JetBrains Mono');
  });

  test('the SIL Open Font Licenses of both fonts are registered', () async {
    LicenseRegistry.reset();
    addTearDown(LicenseRegistry.reset);

    registerFontLicenses();
    final entries = await LicenseRegistry.licenses.toList();

    for (final family in ['Manrope', 'JetBrains Mono']) {
      final matching = entries.where(
        (entry) => entry.packages.contains(family),
      );
      expect(matching, hasLength(1), reason: family);
      expect(
        matching.single.paragraphs
            .map((paragraph) => paragraph.text)
            .join('\n'),
        contains('SIL Open Font License'),
        reason: family,
      );
    }
  });
}
