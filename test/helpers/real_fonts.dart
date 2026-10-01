import 'package:flutter/services.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// Loads the bundled Manrope and JetBrains Mono weights and the Material icon font.
///
/// Widget tests normally draw text and icons with a placeholder font; the
/// design-review screenshots need the real ones.
Future<void> loadRealFonts() async {
  final manrope = FontLoader(AppTypography.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    manrope.addFont(rootBundle.load('assets/fonts/Manrope-$weight.ttf'));
  }
  await manrope.load();

  final mono = FontLoader(AppTypography.monoFontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    mono.addFont(rootBundle.load('assets/fonts/JetBrainsMono-$weight.ttf'));
  }
  await mono.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}
