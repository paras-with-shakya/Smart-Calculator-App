import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/app/app.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';

/// The root widget: the Riverpod scope, configured for the app, around
/// [SmartCalculatorApp].
///
/// `main` and the widget tests both start the app through this widget, so
/// tests run the same configuration as the real app.
class AppRoot extends StatelessWidget {
  /// Creates the root with the [preferences] loaded at startup, plus any
  /// further [overrides] (tests use this for an in-memory database).
  ///
  /// Riverpod resolves an unscoped provider at the app's one root
  /// `ProviderScope`, wherever its override is set, so every override the
  /// app needs must be in this single list rather than in a `ProviderScope`
  /// wrapped around [AppRoot].
  const AppRoot({
    super.key,
    required this.preferences,
    this.overrides = const [],
  });

  /// Preferences returned by `openPreferences`.
  final SharedPreferencesWithCache preferences;

  /// Further overrides, applied after the preferences override.
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) => ProviderScope(
    retry: _neverRetry,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      ...overrides,
    ],
    child: const SmartCalculatorApp(),
  );
}

/// Riverpod 3 retries failing providers automatically. The app turns that off
/// so failures surface immediately and the same way every time.
Duration? _neverRetry(int retryCount, Object error) => null;
