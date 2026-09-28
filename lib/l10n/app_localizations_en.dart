// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Calculator';

  @override
  String get modeBasic => 'Basic';

  @override
  String get modeScientific => 'Scientific';

  @override
  String get modeProgrammer => 'Programmer';

  @override
  String get modeFinance => 'Finance';

  @override
  String get modeConverter => 'Converter';

  @override
  String get modeDate => 'Date';

  @override
  String get changeModeTooltip => 'Change mode';

  @override
  String get modeSheetTitle => 'Modes';

  @override
  String get modeNotAvailableYet => 'This mode isn\'t available yet.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyNotAvailableYet => 'History isn\'t available yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';
}
