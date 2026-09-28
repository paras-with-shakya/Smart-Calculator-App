import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/app/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every Manrope weight is bundled', () async {
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final font = await rootBundle.load('assets/fonts/Manrope-$weight.ttf');
      expect(font.lengthInBytes, greaterThan(0), reason: weight);
    }
  });

  test("Manrope's SIL Open Font License is registered", () async {
    LicenseRegistry.reset();
    addTearDown(LicenseRegistry.reset);

    registerFontLicenses();
    final entries = await LicenseRegistry.licenses.toList();

    final manrope = entries.where(
      (entry) => entry.packages.contains('Manrope'),
    );
    expect(manrope, hasLength(1));
    expect(
      manrope.single.paragraphs.map((paragraph) => paragraph.text).join('\n'),
      contains('SIL Open Font License'),
    );
  });
}
