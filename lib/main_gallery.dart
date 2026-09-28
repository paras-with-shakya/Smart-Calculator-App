import 'package:flutter/widgets.dart';
import 'package:smart_calculator/gallery/gallery_app.dart';

/// Debug-only entry point for the component gallery used in design reviews:
///
///     flutter run -t lib/main_gallery.dart
///
/// The app's own entry point (`main.dart`) never imports the gallery, so it
/// is not part of app builds.
void main() => runApp(const GalleryApp());
