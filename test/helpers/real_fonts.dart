import 'package:flutter/services.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// Loads the bundled Manrope weights and the Material icon font.
///
/// Widget tests normally draw text and icons with a placeholder font; the
/// design-review screenshots need the real ones.
Future<void> loadRealFonts() async {
  final manrope = FontLoader(AppTypography.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    manrope.addFont(rootBundle.load('assets/fonts/Manrope-$weight.ttf'));
  }
  await manrope.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}
