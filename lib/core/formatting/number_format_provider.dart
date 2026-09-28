import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';

/// The number format of the device's region (DEC-037).
///
/// The app's language is English only, so the resolved app locale has no
/// region; this reads the device locale instead (for example `en_IN`). A
/// region change while the app runs takes effect on the next start.
final Provider<LocalizedNumberFormat> numberFormatProvider =
    Provider<LocalizedNumberFormat>(
      (ref) => LocalizedNumberFormat(
        WidgetsBinding.instance.platformDispatcher.locale.toString(),
      ),
    );
