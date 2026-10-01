import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset holding the SIL Open Font License of the bundled Manrope font.
const String manropeLicenseAsset = 'assets/fonts/Manrope-OFL.txt';

/// Asset holding the SIL Open Font License of the bundled JetBrains Mono
/// font (programmer mode's readouts).
const String jetBrainsMonoLicenseAsset = 'assets/fonts/JetBrainsMono-OFL.txt';

/// Adds the bundled fonts' licences to Flutter's licence registry, so they
/// appear on the licences page. The SIL Open Font License requires its text
/// to be distributed with the font.
///
/// The licence files are only read when the licences page asks for them.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final manrope = await rootBundle.loadString(manropeLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Manrope'], manrope);
    final jetBrainsMono = await rootBundle.loadString(
      jetBrainsMonoLicenseAsset,
    );
    yield LicenseEntryWithLineBreaks(const ['JetBrains Mono'], jetBrainsMono);
  });
}
