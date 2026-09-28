// The component gallery is a debug-only developer tool (lib/main_gallery.dart).
// It is not part of the app, so its copy is not localized.
import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/core/widgets/app_header.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/gallery/gallery_sections.dart';

/// The component gallery: every design token and component, with switches
/// for the theme, high contrast and text size. Used for design reviews.
class GalleryApp extends StatefulWidget {
  /// Creates the gallery.
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _highContrast = false;
  int _textScaleIndex = 0;

  /// The text sizes the gallery cycles through: 100%, 150% and 200%.
  static const List<double> _textScales = [1, 1.5, 2];

  @override
  Widget build(BuildContext context) {
    final dark = _themeMode == ThemeMode.dark;
    final textScale = _textScales[_textScaleIndex];
    return MaterialApp(
      title: 'Smart Calculator design system',
      debugShowCheckedModeBanner: false,
      theme: _highContrast ? AppTheme.highContrastLight : AppTheme.light,
      darkTheme: _highContrast ? AppTheme.highContrastDark : AppTheme.dark,
      themeMode: _themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        appBar: AppHeader(
          title: Text('Design system · ${(textScale * 100).round()}%'),
          actions: [
            AppIconButton(
              icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              tooltip: dark ? 'Use light theme' : 'Use dark theme',
              onPressed: () => setState(
                () => _themeMode = dark ? ThemeMode.light : ThemeMode.dark,
              ),
            ),
            AppIconButton(
              icon: _highContrast ? Icons.contrast : Icons.contrast_outlined,
              tooltip: _highContrast
                  ? 'Turn off high contrast'
                  : 'Turn on high contrast',
              onPressed: () => setState(() => _highContrast = !_highContrast),
            ),
            AppIconButton(
              icon: Icons.format_size,
              tooltip: 'Change text size',
              onPressed: () => setState(
                () => _textScaleIndex =
                    (_textScaleIndex + 1) % _textScales.length,
              ),
            ),
          ],
        ),
        body: ListView(
          children: [
            for (final section in GallerySection.values)
              GallerySectionView(section),
          ],
        ),
      ),
    );
  }
}
