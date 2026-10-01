import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current local date and time.
///
/// A provider so tests can pin "today". It returns *local* wall-clock time;
/// callers read only the year, month and day from it (through
/// `calendarDate`), never the instant.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);
