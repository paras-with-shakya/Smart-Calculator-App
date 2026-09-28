import 'package:flutter/widgets.dart';
import 'package:smart_calculator/app/app_root.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';

/// Loads the preferences before the first frame, so the saved theme applies
/// immediately, then starts the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await openPreferences();
  runApp(AppRoot(preferences: preferences));
}
