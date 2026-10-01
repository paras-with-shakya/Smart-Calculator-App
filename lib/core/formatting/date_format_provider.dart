import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/core/formatting/localized_date_format.dart';

/// The date format of the device's region, read the same way (and for the
/// same reason) as `numberFormatProvider` (DEC-037).
final Provider<LocalizedDateFormat> dateFormatProvider =
    Provider<LocalizedDateFormat>(
      (ref) => LocalizedDateFormat(
        WidgetsBinding.instance.platformDispatcher.locale.toString(),
      ),
    );
