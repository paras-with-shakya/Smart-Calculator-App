import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:smart_calculator/app/app_root.dart';
import 'package:smart_calculator/core/persistence/preferences.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// English strings, so tests do not hard-code copy.
final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

/// Window sizes, in logical pixels, for each layout the shell supports.
abstract final class TestWindows {
  /// Compact.
  static const Size phonePortrait = Size(390, 844);

  /// Medium.
  static const Size tabletPortrait = Size(800, 1280);

  /// Expanded.
  static const Size tabletLandscape = Size(1280, 800);

  /// Expanded, and too short for every rail destination at once.
  static const Size phoneLandscape = Size(844, 390);
}

/// Replaces the device's preferences store with an empty in-memory one.
///
/// Preferences opened afterwards in the same test share this store, which is
/// how a test simulates restarting the app.
void useInMemoryPreferences() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
}

/// Starts the app the way `main` does, in a window of [size].
///
/// Uses [preferences] if given, otherwise opens them from the current store.
Future<void> pumpApp(
  WidgetTester tester, {
  Size size = TestWindows.phonePortrait,
  SharedPreferencesWithCache? preferences,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppRoot(preferences: preferences ?? await openPreferences()),
  );
  await tester.pumpAndSettle();
}
