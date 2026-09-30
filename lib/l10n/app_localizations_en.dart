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
      'This removes every calculation in your history. This can\'t be undone.';

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
  String get historyTabLabel => 'History';

  @override
  String get savedTabLabel => 'Saved';

  @override
  String get savedSaveTooltip => 'Save calculation';

  @override
  String get savedSaveSheetTitle => 'Save calculation';

  @override
  String get savedNameLabel => 'Name';

  @override
  String get savedNameHint => 'e.g. Rent budget';

  @override
  String get savedSaveAction => 'Save';

  @override
  String savedSavedMessage(String name) {
    return 'Saved “$name”';
  }

  @override
  String get savedRenameTooltip => 'Rename';

  @override
  String get savedRenameSheetTitle => 'Rename';

  @override
  String get savedRenameAction => 'Rename';

  @override
  String get savedDeleteTooltip => 'Delete';

  @override
  String get savedEmptyTitle => 'No saved calculations yet';

  @override
  String get savedEmptyMessage =>
      'Save a result from your history to find it here later.';

  @override
  String get savedSearchLabel => 'Search saved calculations';

  @override
  String get savedSearchEmptyMessage => 'No matching saved calculations.';

  @override
  String get savedClearAllTooltip => 'Clear all saved calculations';

  @override
  String get savedClearAllConfirmTitle => 'Clear all saved calculations?';

  @override
  String get savedClearAllConfirmMessage =>
      'This removes every saved calculation. This can\'t be undone.';

  @override
  String get savedClearAllConfirmAction => 'Clear all';

  @override
  String savedEntrySemanticLabel(
    String name,
    String expression,
    String result,
  ) {
    return '$name: $expression equals $result';
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
  String get spokenPower => 'to the power of';

  @override
  String get spokenFactorial => 'factorial';

  @override
  String get spokenPi => 'pi';

  @override
  String get spokenEuler => 'e';

  @override
  String get spokenFunctionSin => 'sine of';

  @override
  String get spokenFunctionCos => 'cosine of';

  @override
  String get spokenFunctionTan => 'tangent of';

  @override
  String get spokenFunctionAsin => 'inverse sine of';

  @override
  String get spokenFunctionAcos => 'inverse cosine of';

  @override
  String get spokenFunctionAtan => 'inverse tangent of';

  @override
  String get spokenFunctionSinh => 'hyperbolic sine of';

  @override
  String get spokenFunctionCosh => 'hyperbolic cosine of';

  @override
  String get spokenFunctionTanh => 'hyperbolic tangent of';

  @override
  String get spokenFunctionLog => 'log base 10 of';

  @override
  String get spokenFunctionLn => 'natural log of';

  @override
  String get spokenFunctionSqrt => 'square root of';

  @override
  String get spokenFunctionCbrt => 'cube root of';

  @override
  String get spokenFunctionAbs => 'absolute value of';

  @override
  String get errorIncomplete => 'Incomplete expression';

  @override
  String get errorInvalid => 'Invalid expression';

  @override
  String get errorDivisionByZero => 'Can\'t divide by zero';

  @override
  String get errorOverflow => 'Number too large';

  @override
  String get errorUndefined => 'Undefined result';

  @override
  String get keySin => 'sin';

  @override
  String get keySinLabel => 'Sine';

  @override
  String get keyCos => 'cos';

  @override
  String get keyCosLabel => 'Cosine';

  @override
  String get keyTan => 'tan';

  @override
  String get keyTanLabel => 'Tangent';

  @override
  String get keyAsin => 'sin⁻¹';

  @override
  String get keyAsinLabel => 'Inverse sine';

  @override
  String get keyAcos => 'cos⁻¹';

  @override
  String get keyAcosLabel => 'Inverse cosine';

  @override
  String get keyAtan => 'tan⁻¹';

  @override
  String get keyAtanLabel => 'Inverse tangent';

  @override
  String get keySinh => 'sinh';

  @override
  String get keySinhLabel => 'Hyperbolic sine';

  @override
  String get keyCosh => 'cosh';

  @override
  String get keyCoshLabel => 'Hyperbolic cosine';

  @override
  String get keyTanh => 'tanh';

  @override
  String get keyTanhLabel => 'Hyperbolic tangent';

  @override
  String get keyLog => 'log';

  @override
  String get keyLogLabel => 'Log base 10';

  @override
  String get keyLn => 'ln';

  @override
  String get keyLnLabel => 'Natural log';

  @override
  String get keySqrt => '√';

  @override
  String get keySqrtLabel => 'Square root';

  @override
  String get keyCbrt => '∛';

  @override
  String get keyCbrtLabel => 'Cube root';

  @override
  String get keyAbs => 'abs';

  @override
  String get keyAbsLabel => 'Absolute value';

  @override
  String get keySquare => 'x²';

  @override
  String get keySquareLabel => 'Square';

  @override
  String get keyCube => 'x³';

  @override
  String get keyCubeLabel => 'Cube';

  @override
  String get keyPowerOfTen => '10ˣ';

  @override
  String get keyPowerOfTenLabel => 'Power of ten';

  @override
  String get keyPowerOfE => 'eˣ';

  @override
  String get keyPowerOfELabel => 'Power of e';

  @override
  String get keyPowerLabel => 'Power';

  @override
  String get keyFactorialLabel => 'Factorial';

  @override
  String get keyPiLabel => 'Pi';

  @override
  String get keyEulerLabel => 'Euler\'s number';

  @override
  String get keyAngleModeDegrees => 'DEG';

  @override
  String get keyAngleModeDegreesLabel => 'Angle mode, degrees';

  @override
  String get keyAngleModeRadians => 'RAD';

  @override
  String get keyAngleModeRadiansLabel => 'Angle mode, radians';

  @override
  String get keySecond => '2nd';

  @override
  String get keySecondLabel => 'Second function';

  @override
  String get scientificGroupTrigonometry => 'Trigonometry';

  @override
  String get scientificGroupHyperbolic => 'Hyperbolic';

  @override
  String get scientificGroupLogarithmsAndPowers => 'Logarithms and powers';

  @override
  String get scientificGroupRoots => 'Roots';

  @override
  String get scientificGroupOther => 'Other';
}
