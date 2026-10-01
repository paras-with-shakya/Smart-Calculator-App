import 'package:flutter/widgets.dart';
import 'package:smart_calculator/app/app_root.dart';
import 'package:smart_calculator/app/font_licenses.dart';
import 'package:smart_calculator/core/formatting/localized_date_format.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';

/// Loads the preferences before the first frame, so the saved theme applies
/// immediately, then starts the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  await initializeLocalizedDates(
    WidgetsBinding.instance.platformDispatcher.locale.toString(),
  );
  final preferences = await openPreferences();
  runApp(AppRoot(preferences: preferences));
}
