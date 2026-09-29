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
  String get historyEmptyTitle => 'No history yet';

  @override
  String get historyEmptyMessage =>
      'Every result you calculate with “=” appears here.';

  @override
  String get historySearchLabel => 'Search history';

  @override
  String get historySearchEmptyMessage => 'No matching calculations.';

  @override
  String get historyClearAllTooltip => 'Clear all history';

  @override
  String get historyClearAllConfirmTitle => 'Clear all history?';

  @override
  String get historyClearAllConfirmMessage =>
      'This removes every saved calculation. This can\'t be undone.';

  @override
  String get historyClearAllConfirmAction => 'Clear all';

  @override
  String get historyDeleteTooltip => 'Delete';

  @override
  String get historyCopyTooltip => 'Copy result';

  @override
  String historyCopiedMessage(String value) {
    return 'Copied $value';
  }

  @override
  String historyEntrySemanticLabel(String expression, String result) {
    return '$expression equals $result';
  }

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

  @override
  String get keyAllClear => 'AC';

  @override
  String get keyAllClearLabel => 'All clear';

  @override
  String get keyBrackets => '( )';

  @override
  String get keyBracketsLabel => 'Brackets';

  @override
  String get keyPercentLabel => 'Percent';

  @override
  String get keyDivideLabel => 'Divide';

  @override
  String get keyMultiplyLabel => 'Multiply';

  @override
  String get keySubtractLabel => 'Minus';

  @override
  String get keyAddLabel => 'Plus';

  @override
  String get keyEqualsLabel => 'Equals';

  @override
  String get keyDecimalPointLabel => 'Decimal point';

  @override
  String get keyBackspaceLabel => 'Backspace';

  @override
  String get memoryClear => 'MC';

  @override
  String get memoryClearLabel => 'Memory clear';

  @override
  String get memoryRecall => 'MR';

  @override
  String get memoryRecallLabel => 'Memory recall';

  @override
  String get memoryAdd => 'M+';

  @override
  String get memoryAddLabel => 'Memory add';

  @override
  String get memorySubtract => 'M−';

  @override
  String get memorySubtractLabel => 'Memory subtract';

  @override
  String get memoryStore => 'MS';

  @override
  String get memoryStoreLabel => 'Memory store';

  @override
  String get memoryIndicator => 'M';

  @override
  String memoryIndicatorLabel(String value) {
    return 'Memory: $value';
  }

  @override
  String displayResultLabel(String value) {
    return 'Equals $value';
  }

  @override
  String displayPreviewLabel(String value) {
    return 'Preview: $value';
  }

  @override
  String get spokenPlus => 'plus';

  @override
  String get spokenMinus => 'minus';

  @override
  String get spokenTimes => 'times';

  @override
  String get spokenDividedBy => 'divided by';

  @override
  String get spokenPercent => 'percent';

  @override
  String get spokenOpenBracket => 'open bracket';

  @override
  String get spokenCloseBracket => 'close bracket';

  @override
  String get errorIncomplete => 'Incomplete expression';

  @override
  String get errorInvalid => 'Invalid expression';

  @override
  String get errorDivisionByZero => 'Can\'t divide by zero';

  @override
  String get errorOverflow => 'Number too large';
}
