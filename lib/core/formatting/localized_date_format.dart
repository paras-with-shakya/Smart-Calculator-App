import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Shows calendar dates the way a region writes them: its order of day,
/// month and year, and its month and weekday names (for example
/// `Sun, 8 Mar 2026` in India, `Sun, Mar 8, 2026` in the US).
///
/// It formats a date's year, month and day exactly as given and never
/// converts it to another time zone, so a calendar date (DEC-053) can't
/// shift by a day.
final class LocalizedDateFormat {
  const LocalizedDateFormat._(this._localeName);

  /// The format for [localeName], such as `en_IN`. Unknown locales fall
  /// back to their language, then to English.
  factory LocalizedDateFormat(String localeName) => LocalizedDateFormat._(
    Intl.verifiedLocale(
          localeName,
          DateFormat.localeExists,
          onFailure: (_) => 'en',
        ) ??
        'en',
  );

  final String _localeName;

  /// A compact date with the short weekday: `Sun, 8 Mar 2026`.
  String short(DateTime date) => DateFormat.yMMMEd(_localeName).format(date);

  /// A date with the full weekday and month: `Sunday, 8 March 2026`.
  String long(DateTime date) => DateFormat.yMMMMEEEEd(_localeName).format(date);
}

/// Loads the date names and patterns of [localeName]'s region.
///
/// The app's own language is English only, so Flutter loads date data for
/// plain `en` and nothing else; without this, a device set to `en_IN` would
/// get US-ordered dates. Call it once at startup. A region `intl` has no
/// data for is ignored: [LocalizedDateFormat] falls back to English.
Future<void> initializeLocalizedDates(String localeName) async {
  try {
    await initializeDateFormatting(localeName);
  } on Object {
    // No data for this region: dates stay in English.
  }
}
