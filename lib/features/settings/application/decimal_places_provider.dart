import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';

/// How many places Basic and Scientific results are rounded to, or null to
/// keep up to 12 significant digits.
final Provider<int?> decimalPlacesProvider = Provider<int?>(
  (ref) => ref.watch(appSettingsProvider.select((s) => s.decimalPlaces.places)),
);
