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

  @override
  String get keyToggleSignLabel => 'Toggle sign';

  @override
  String get converterCategoryLength => 'Length';

  @override
  String get converterCategoryWeight => 'Weight';

  @override
  String get converterCategoryTemperature => 'Temperature';

  @override
  String get converterCategoryArea => 'Area';

  @override
  String get converterCategoryVolume => 'Volume';

  @override
  String get converterCategoryTime => 'Time';

  @override
  String get converterCategoryCurrency => 'Currency';

  @override
  String get converterUnitPickerTitle => 'Choose a unit';

  @override
  String get converterUnitSearchLabel => 'Search units';

  @override
  String get converterUnitSearchNoMatches => 'No matching units.';

  @override
  String get converterFromLabel => 'From';

  @override
  String get converterToLabel => 'To';

  @override
  String converterEditRateTooltip(String currency) {
    return 'Edit $currency exchange rate';
  }

  @override
  String converterEditRateTitle(String currency) {
    return '$currency rate';
  }

  @override
  String get converterEditRateLabel => 'Units per 1 USD';

  @override
  String get converterEditRateSaveAction => 'Save';

  @override
  String get converterSwapTooltip => 'Swap units';

  @override
  String get financialErrorMustBePositive => 'Enter a value greater than 0';

  @override
  String get financialErrorMustBeNonNegative => 'Enter a value of 0 or more';

  @override
  String financialErrorTooLarge(int max) {
    return 'Enter at most $max';
  }

  @override
  String get financialErrorMustBePositiveInteger =>
      'Enter a whole number of 1 or more';

  @override
  String get financialResultPlaceholder =>
      'Enter every amount above to see a result.';

  @override
  String get financialToolEmi => 'EMI';

  @override
  String get financialToolSimpleInterest => 'Simple interest';

  @override
  String get financialToolCompoundInterest => 'Compound interest';

  @override
  String get financialToolGst => 'GST';

  @override
  String get financialToolDiscount => 'Discount';

  @override
  String get financialToolTip => 'Tip';

  @override
  String get financialToolPercentage => 'Percentage';

  @override
  String get financialEmiPrincipalLabel => 'Loan amount';

  @override
  String get financialEmiRateLabel => 'Interest rate (annual)';

  @override
  String get financialEmiTenureLabel => 'Tenure';

  @override
  String get financialTenureUnitYears => 'Years';

  @override
  String get financialTenureUnitMonths => 'Months';

  @override
  String get financialEmiMonthlyLabel => 'Monthly EMI';

  @override
  String get financialEmiTotalInterestLabel => 'Total interest';

  @override
  String get financialEmiTotalPaymentLabel => 'Total payment';

  @override
  String get financialEmiChartPrincipalLabel => 'Principal';

  @override
  String get financialEmiChartInterestLabel => 'Interest';

  @override
  String get financialSiPrincipalLabel => 'Principal';

  @override
  String get financialSiRateLabel => 'Interest rate (annual)';

  @override
  String get financialSiTimeLabel => 'Time (years)';

  @override
  String get financialSiInterestLabel => 'Interest';

  @override
  String get financialSiTotalLabel => 'Total amount';

  @override
  String get financialCiPrincipalLabel => 'Principal';

  @override
  String get financialCiRateLabel => 'Interest rate (annual)';

  @override
  String get financialCiTimeLabel => 'Time (years)';

  @override
  String get financialCiFrequencyLabel => 'Compounding';

  @override
  String get financialCiFrequencyAnnual => 'Annual';

  @override
  String get financialCiFrequencySemiAnnual => 'Semi-annual';

  @override
  String get financialCiFrequencyQuarterly => 'Quarterly';

  @override
  String get financialCiFrequencyMonthly => 'Monthly';

  @override
  String get financialCiInterestLabel => 'Interest earned';

  @override
  String get financialCiTotalLabel => 'Total amount';

  @override
  String get financialGstAmountLabel => 'Amount';

  @override
  String get financialGstRateLabel => 'GST rate';

  @override
  String get financialGstModeLabel => 'GST is';

  @override
  String get financialGstModeExclusive => 'Added to amount';

  @override
  String get financialGstModeInclusive => 'Already included';

  @override
  String get financialGstSupplyLabel => 'Supply type';

  @override
  String get financialGstSupplyIntraState => 'Intra-state (CGST+SGST)';

  @override
  String get financialGstSupplyInterState => 'Inter-state (IGST)';

  @override
  String get financialGstBaseLabel => 'Base amount';

  @override
  String get financialGstCgstLabel => 'CGST';

  @override
  String get financialGstSgstLabel => 'SGST';

  @override
  String get financialGstIgstLabel => 'IGST';

  @override
  String get financialGstTotalLabel => 'Total amount';

  @override
  String get financialGstAmountResultLabel => 'GST amount';

  @override
  String get financialDiscountPriceLabel => 'Price';

  @override
  String get financialDiscountPercentLabel => 'Discount';

  @override
  String get financialDiscountFinalPriceLabel => 'Final price';

  @override
  String get financialDiscountAmountLabel => 'You save';

  @override
  String get financialTipBillLabel => 'Bill amount';

  @override
  String get financialTipPercentLabel => 'Tip';

  @override
  String get financialTipSplitLabel => 'Split between';

  @override
  String get financialTipPerPersonLabel => 'Per person';

  @override
  String get financialTipAmountLabel => 'Tip amount';

  @override
  String get financialTipTotalLabel => 'Total';

  @override
  String get financialPercentOfXLabel => 'Percentage (%)';

  @override
  String get financialPercentOfYLabel => 'Of this amount';

  @override
  String get financialPercentWhatXLabel => 'This amount';

  @override
  String get financialPercentWhatYLabel => 'Out of this total';

  @override
  String get financialPercentChangeXLabel => 'Percentage (%)';

  @override
  String get financialPercentChangeYLabel => 'Starting amount';

  @override
  String get financialPercentOpPercentOf => 'X% of Y';

  @override
  String get financialPercentOpWhatPercent => 'X is what % of Y';

  @override
  String get financialPercentOpChangeBy => 'Increase/decrease Y by X%';

  @override
  String get financialPercentOperationLabel => 'Calculate';

  @override
  String get financialPercentDirectionIncrease => 'Increase';

  @override
  String get financialPercentDirectionDecrease => 'Decrease';

  @override
  String get financialPercentResultLabel => 'Result';

  @override
  String get dateToolPickerLabel => 'Calculate';

  @override
  String get dateToolDifference => 'Difference';

  @override
  String get dateToolOffset => 'Add or subtract';

  @override
  String get dateFromLabel => 'From';

  @override
  String get dateToLabel => 'To';

  @override
  String get dateStartLabel => 'Start date';

  @override
  String get datePickerHelp => 'Select date';

  @override
  String get dateDirectionAdd => 'Add';

  @override
  String get dateDirectionSubtract => 'Subtract';

  @override
  String get dateAmountLabel => 'Amount';

  @override
  String get dateUnitLabel => 'Unit';

  @override
  String get dateUnitDays => 'Days';

  @override
  String get dateUnitWeeks => 'Weeks';

  @override
  String get dateUnitMonths => 'Months';

  @override
  String get dateUnitYears => 'Years';

  @override
  String dateErrorAmountTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Enter $maxString or less';
  }

  @override
  String get dateErrorOutOfRange =>
      'That date is outside the supported years (1 to 9999).';

  @override
  String get dateDifferencePlaceholder =>
      'Pick two dates to see the difference.';

  @override
  String get dateOffsetPlaceholder => 'Enter an amount to see the date.';

  @override
  String get dateResultDifference => 'Difference';

  @override
  String get dateResultTotalDays => 'Total days';

  @override
  String get dateResultWeeks => 'Weeks and days';

  @override
  String get dateResultTotalMonths => 'Total months';

  @override
  String get dateResultDate => 'Resulting date';

  @override
  String dateYears(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString years',
      one: '$countString year',
    );
    return '$_temp0';
  }

  @override
  String dateMonths(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString months',
      one: '$countString month',
    );
    return '$_temp0';
  }

  @override
  String dateWeeks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString weeks',
      one: '$countString week',
    );
    return '$_temp0';
  }

  @override
  String dateDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '$countString day',
    );
    return '$_temp0';
  }

  @override
  String dateSpanJoin(String first, String second) {
    return '$first, $second';
  }
}
