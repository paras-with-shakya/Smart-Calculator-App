import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/app/app.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';

/// The root widget: the Riverpod scope, configured for the app, around
/// [SmartCalculatorApp].
///
/// `main` and the widget tests both start the app through this widget, so
/// tests run the same configuration as the real app.
class AppRoot extends StatelessWidget {
  /// Creates the root with the [preferences] loaded at startup.
  const AppRoot({super.key, required this.preferences});

  /// Preferences returned by `openPreferences`.
  final SharedPreferencesWithCache preferences;

  @override
  Widget build(BuildContext context) => ProviderScope(
    retry: _neverRetry,
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    child: const SmartCalculatorApp(),
  );
}

/// Riverpod 3 retries failing providers automatically. The app turns that off
/// so failures surface immediately and the same way every time.
Duration? _neverRetry(int retryCount, Object error) => null;
