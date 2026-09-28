import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset holding the SIL Open Font License of the bundled Manrope font.
const String manropeLicenseAsset = 'assets/fonts/Manrope-OFL.txt';

/// Adds the bundled fonts' licences to Flutter's licence registry, so they
/// appear on the licences page. The SIL Open Font License requires its text
/// to be distributed with the font.
///
/// The licence file is only read when the licences page asks for it.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(manropeLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Manrope'], text);
  });
}
