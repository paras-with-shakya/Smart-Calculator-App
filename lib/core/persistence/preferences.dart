import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_calculator/core/persistence/preference_keys.dart';

/// Opens the app's preferences and loads every allowed key into memory, so
/// later reads are synchronous.
///
/// Called once at startup, before the first frame, so the saved theme is
/// applied without a flash of the default one.
Future<SharedPreferencesWithCache> openPreferences() =>
    SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: PreferenceKeys.all,
      ),
    );

/// The preferences opened by [openPreferences].
///
/// It has no default value: `AppRoot` overrides it with the preloaded
/// instance, and tests override it the same way.
final Provider<SharedPreferencesWithCache> sharedPreferencesProvider =
    Provider<SharedPreferencesWithCache>(
      (ref) => throw StateError(
        'sharedPreferencesProvider must be overridden with the instance '
        'returned by openPreferences().',
      ),
    );
