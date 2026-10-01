import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Name of the app, shown by the operating system and in the task switcher.
  ///
  /// In en, this message translates to:
  /// **'Smart Calculator'**
  String get appTitle;

  /// Name of the basic calculator mode.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get modeBasic;

  /// Name of the scientific calculator mode.
  ///
  /// In en, this message translates to:
  /// **'Scientific'**
  String get modeScientific;

  /// Name of the programmer calculator mode (binary, octal, decimal and hexadecimal).
  ///
  /// In en, this message translates to:
  /// **'Programmer'**
  String get modeProgrammer;

  /// Name of the financial calculators mode (loans, interest, tax, discounts).
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get modeFinance;

  /// Name of the unit converter mode.
  ///
  /// In en, this message translates to:
  /// **'Converter'**
  String get modeConverter;

  /// Name of the date calculator mode (date differences, adding or subtracting days).
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get modeDate;

  /// Tooltip and accessibility hint for the button that opens the list of calculator modes.
  ///
  /// In en, this message translates to:
  /// **'Change mode'**
  String get changeModeTooltip;

  /// Heading of the sheet listing all calculator modes.
  ///
  /// In en, this message translates to:
  /// **'Modes'**
  String get modeSheetTitle;

  /// Shown in place of a calculator mode that has not been built yet.
  ///
  /// In en, this message translates to:
  /// **'This mode isn\'t available yet.'**
  String get modeNotAvailableYet;

  /// Title of the calculation history page and panel, and tooltip of the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Heading shown when the calculation history is empty.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmptyTitle;

  /// Message shown when the calculation history is empty.
  ///
  /// In en, this message translates to:
  /// **'Every result you calculate with “=” appears here.'**
  String get historyEmptyMessage;

  /// Label of the text field that filters the calculation history.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get historySearchLabel;

  /// Shown when a history search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching calculations.'**
  String get historySearchEmptyMessage;

  /// Tooltip and accessibility label of the button that clears the whole calculation history.
  ///
  /// In en, this message translates to:
  /// **'Clear all history'**
  String get historyClearAllTooltip;

  /// Title of the dialog confirming that the whole calculation history should be cleared.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get historyClearAllConfirmTitle;

  /// Message of the dialog confirming that the whole calculation history should be cleared.
  ///
  /// In en, this message translates to:
  /// **'This removes every calculation in your history. This can\'t be undone.'**
  String get historyClearAllConfirmMessage;

  /// Confirm button of the dialog that clears the whole calculation history.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get historyClearAllConfirmAction;

  /// Tooltip and accessibility label of the button that deletes one history entry.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDeleteTooltip;

  /// Tooltip and accessibility label of the button that copies one history entry's result.
  ///
  /// In en, this message translates to:
  /// **'Copy result'**
  String get historyCopyTooltip;

  /// Shown briefly after copying a history entry's result.
  ///
  /// In en, this message translates to:
  /// **'Copied {value}'**
  String historyCopiedMessage(String value);

  /// Accessibility label of a history entry; tapping it reuses the result.
  ///
  /// In en, this message translates to:
  /// **'{expression} equals {result}'**
  String historyEntrySemanticLabel(String expression, String result);

  /// Label of the tab showing calculation history, next to the saved-calculations tab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTabLabel;

  /// Label of the tab showing saved calculations, next to the history tab.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTabLabel;

  /// Tooltip and accessibility label of the button that saves a history entry as a named, kept calculation.
  ///
  /// In en, this message translates to:
  /// **'Save calculation'**
  String get savedSaveTooltip;

  /// Heading of the sheet where the user names a calculation before saving it.
  ///
  /// In en, this message translates to:
  /// **'Save calculation'**
  String get savedSaveSheetTitle;

  /// Label of the text field for a saved calculation's name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get savedNameLabel;

  /// Example text shown in the empty name field when saving or renaming a calculation.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent budget'**
  String get savedNameHint;

  /// Button that confirms saving a calculation under the name typed.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savedSaveAction;

  /// Shown briefly after saving a calculation.
  ///
  /// In en, this message translates to:
  /// **'Saved “{name}”'**
  String savedSavedMessage(String name);

  /// Tooltip and accessibility label of the button that renames a saved calculation.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get savedRenameTooltip;

  /// Heading of the sheet where the user renames a saved calculation.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get savedRenameSheetTitle;

  /// Button that confirms renaming a saved calculation.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get savedRenameAction;

  /// Tooltip and accessibility label of the button that deletes one saved calculation.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get savedDeleteTooltip;

  /// Heading shown when there are no saved calculations.
  ///
  /// In en, this message translates to:
  /// **'No saved calculations yet'**
  String get savedEmptyTitle;

  /// Message shown when there are no saved calculations.
  ///
  /// In en, this message translates to:
  /// **'Save a result from your history to find it here later.'**
  String get savedEmptyMessage;

  /// Label of the text field that filters saved calculations.
  ///
  /// In en, this message translates to:
  /// **'Search saved calculations'**
  String get savedSearchLabel;

  /// Shown when a search of saved calculations matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching saved calculations.'**
  String get savedSearchEmptyMessage;

  /// Tooltip and accessibility label of the button that clears every saved calculation.
  ///
  /// In en, this message translates to:
  /// **'Clear all saved calculations'**
  String get savedClearAllTooltip;

  /// Title of the dialog confirming that every saved calculation should be cleared.
  ///
  /// In en, this message translates to:
  /// **'Clear all saved calculations?'**
  String get savedClearAllConfirmTitle;

  /// Message of the dialog confirming that every saved calculation should be cleared.
  ///
  /// In en, this message translates to:
  /// **'This removes every saved calculation. This can\'t be undone.'**
  String get savedClearAllConfirmMessage;

  /// Confirm button of the dialog that clears every saved calculation.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get savedClearAllConfirmAction;

  /// Accessibility label of a saved calculation; tapping it reuses the result.
  ///
  /// In en, this message translates to:
  /// **'{name}: {expression} equals {result}'**
  String savedEntrySemanticLabel(String name, String expression, String result);

  /// Title of the settings page, and tooltip of the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Heading of the settings section about the app's look.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// Label of the setting that chooses between the system, light and dark themes.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// Theme option: follow the device's light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme option: always use the light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option: always use the dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Visible label of the calculator key that clears everything. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get keyAllClear;

  /// What screen readers say for the AC key.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get keyAllClearLabel;

  /// Visible label of the single bracket key, which opens or closes a bracket as needed.
  ///
  /// In en, this message translates to:
  /// **'( )'**
  String get keyBrackets;

  /// What screen readers say for the bracket key.
  ///
  /// In en, this message translates to:
  /// **'Brackets'**
  String get keyBracketsLabel;

  /// What screen readers say for the % key.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get keyPercentLabel;

  /// What screen readers say for the ÷ key.
  ///
  /// In en, this message translates to:
  /// **'Divide'**
  String get keyDivideLabel;

  /// What screen readers say for the × key.
  ///
  /// In en, this message translates to:
  /// **'Multiply'**
  String get keyMultiplyLabel;

  /// What screen readers say for the − key.
  ///
  /// In en, this message translates to:
  /// **'Minus'**
  String get keySubtractLabel;

  /// What screen readers say for the + key.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get keyAddLabel;

  /// What screen readers say for the = key.
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get keyEqualsLabel;

  /// What screen readers say for the decimal point key.
  ///
  /// In en, this message translates to:
  /// **'Decimal point'**
  String get keyDecimalPointLabel;

  /// What screen readers say for the key that deletes the last input. Holding it clears everything.
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get keyBackspaceLabel;

  /// Visible label of the key that empties the calculator memory. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'MC'**
  String get memoryClear;

  /// What screen readers say for the MC key.
  ///
  /// In en, this message translates to:
  /// **'Memory clear'**
  String get memoryClearLabel;

  /// Visible label of the key that inserts the value in memory. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'MR'**
  String get memoryRecall;

  /// What screen readers say for the MR key.
  ///
  /// In en, this message translates to:
  /// **'Memory recall'**
  String get memoryRecallLabel;

  /// Visible label of the key that adds the current value to the memory. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'M+'**
  String get memoryAdd;

  /// What screen readers say for the M+ key.
  ///
  /// In en, this message translates to:
  /// **'Memory add'**
  String get memoryAddLabel;

  /// Visible label of the key that subtracts the current value from the memory. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'M−'**
  String get memorySubtract;

  /// What screen readers say for the M− key.
  ///
  /// In en, this message translates to:
  /// **'Memory subtract'**
  String get memorySubtractLabel;

  /// Visible label of the key that stores the current value in the memory. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'MS'**
  String get memoryStore;

  /// What screen readers say for the MS key.
  ///
  /// In en, this message translates to:
  /// **'Memory store'**
  String get memoryStoreLabel;

  /// Badge on the calculator display showing that a value is in memory. Keep it to one or two characters.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get memoryIndicator;

  /// What screen readers say for the memory badge.
  ///
  /// In en, this message translates to:
  /// **'Memory: {value}'**
  String memoryIndicatorLabel(String value);

  /// What screen readers say for the result on the calculator display.
  ///
  /// In en, this message translates to:
  /// **'Equals {value}'**
  String displayResultLabel(String value);

  /// What screen readers say for the live result shown while an expression is typed.
  ///
  /// In en, this message translates to:
  /// **'Preview: {value}'**
  String displayPreviewLabel(String value);

  /// How screen readers say + inside an expression, such as '5 plus 3'.
  ///
  /// In en, this message translates to:
  /// **'plus'**
  String get spokenPlus;

  /// How screen readers say − (subtraction or a negative sign) inside an expression.
  ///
  /// In en, this message translates to:
  /// **'minus'**
  String get spokenMinus;

  /// How screen readers say × inside an expression, such as '5 times 3'.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get spokenTimes;

  /// How screen readers say ÷ inside an expression, such as '6 divided by 3'.
  ///
  /// In en, this message translates to:
  /// **'divided by'**
  String get spokenDividedBy;

  /// How screen readers say % inside an expression, such as '10 percent'.
  ///
  /// In en, this message translates to:
  /// **'percent'**
  String get spokenPercent;

  /// How screen readers say ( inside an expression.
  ///
  /// In en, this message translates to:
  /// **'open bracket'**
  String get spokenOpenBracket;

  /// How screen readers say ) inside an expression.
  ///
  /// In en, this message translates to:
  /// **'close bracket'**
  String get spokenCloseBracket;

  /// How screen readers say ^ inside an expression, such as '2 to the power of 3'.
  ///
  /// In en, this message translates to:
  /// **'to the power of'**
  String get spokenPower;

  /// How screen readers say ! after a number, such as '5 factorial'.
  ///
  /// In en, this message translates to:
  /// **'factorial'**
  String get spokenFactorial;

  /// How screen readers say the constant π.
  ///
  /// In en, this message translates to:
  /// **'pi'**
  String get spokenPi;

  /// How screen readers say the constant e (Euler's number).
  ///
  /// In en, this message translates to:
  /// **'e'**
  String get spokenEuler;

  /// How screen readers say the sin( function opener.
  ///
  /// In en, this message translates to:
  /// **'sine of'**
  String get spokenFunctionSin;

  /// How screen readers say the cos( function opener.
  ///
  /// In en, this message translates to:
  /// **'cosine of'**
  String get spokenFunctionCos;

  /// How screen readers say the tan( function opener.
  ///
  /// In en, this message translates to:
  /// **'tangent of'**
  String get spokenFunctionTan;

  /// How screen readers say the asin( function opener.
  ///
  /// In en, this message translates to:
  /// **'inverse sine of'**
  String get spokenFunctionAsin;

  /// How screen readers say the acos( function opener.
  ///
  /// In en, this message translates to:
  /// **'inverse cosine of'**
  String get spokenFunctionAcos;

  /// How screen readers say the atan( function opener.
  ///
  /// In en, this message translates to:
  /// **'inverse tangent of'**
  String get spokenFunctionAtan;

  /// How screen readers say the sinh( function opener.
  ///
  /// In en, this message translates to:
  /// **'hyperbolic sine of'**
  String get spokenFunctionSinh;

  /// How screen readers say the cosh( function opener.
  ///
  /// In en, this message translates to:
  /// **'hyperbolic cosine of'**
  String get spokenFunctionCosh;

  /// How screen readers say the tanh( function opener.
  ///
  /// In en, this message translates to:
  /// **'hyperbolic tangent of'**
  String get spokenFunctionTanh;

  /// How screen readers say the log( function opener.
  ///
  /// In en, this message translates to:
  /// **'log base 10 of'**
  String get spokenFunctionLog;

  /// How screen readers say the ln( function opener.
  ///
  /// In en, this message translates to:
  /// **'natural log of'**
  String get spokenFunctionLn;

  /// How screen readers say the sqrt( function opener.
  ///
  /// In en, this message translates to:
  /// **'square root of'**
  String get spokenFunctionSqrt;

  /// How screen readers say the cbrt( function opener.
  ///
  /// In en, this message translates to:
  /// **'cube root of'**
  String get spokenFunctionCbrt;

  /// How screen readers say the abs( function opener.
  ///
  /// In en, this message translates to:
  /// **'absolute value of'**
  String get spokenFunctionAbs;

  /// Calculator error: the expression ends too early, such as '5+'.
  ///
  /// In en, this message translates to:
  /// **'Incomplete expression'**
  String get errorIncomplete;

  /// Calculator error: the expression can't be read, such as '5)'.
  ///
  /// In en, this message translates to:
  /// **'Invalid expression'**
  String get errorInvalid;

  /// Calculator error: the expression divides by zero.
  ///
  /// In en, this message translates to:
  /// **'Can\'t divide by zero'**
  String get errorDivisionByZero;

  /// Calculator error: the result is too large to show.
  ///
  /// In en, this message translates to:
  /// **'Number too large'**
  String get errorOverflow;

  /// Calculator error: a function argument is outside its domain, such as the square root of a negative number, log of zero, or the factorial of a negative number.
  ///
  /// In en, this message translates to:
  /// **'Undefined result'**
  String get errorUndefined;

  /// Visible label of the sine key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'sin'**
  String get keySin;

  /// What screen readers say for the sine key.
  ///
  /// In en, this message translates to:
  /// **'Sine'**
  String get keySinLabel;

  /// Visible label of the cosine key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'cos'**
  String get keyCos;

  /// What screen readers say for the cosine key.
  ///
  /// In en, this message translates to:
  /// **'Cosine'**
  String get keyCosLabel;

  /// Visible label of the tangent key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'tan'**
  String get keyTan;

  /// What screen readers say for the tangent key.
  ///
  /// In en, this message translates to:
  /// **'Tangent'**
  String get keyTanLabel;

  /// Visible label of the inverse sine key (2nd of sin).
  ///
  /// In en, this message translates to:
  /// **'sin⁻¹'**
  String get keyAsin;

  /// What screen readers say for the inverse sine key.
  ///
  /// In en, this message translates to:
  /// **'Inverse sine'**
  String get keyAsinLabel;

  /// Visible label of the inverse cosine key (2nd of cos).
  ///
  /// In en, this message translates to:
  /// **'cos⁻¹'**
  String get keyAcos;

  /// What screen readers say for the inverse cosine key.
  ///
  /// In en, this message translates to:
  /// **'Inverse cosine'**
  String get keyAcosLabel;

  /// Visible label of the inverse tangent key (2nd of tan).
  ///
  /// In en, this message translates to:
  /// **'tan⁻¹'**
  String get keyAtan;

  /// What screen readers say for the inverse tangent key.
  ///
  /// In en, this message translates to:
  /// **'Inverse tangent'**
  String get keyAtanLabel;

  /// Visible label of the hyperbolic sine key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'sinh'**
  String get keySinh;

  /// What screen readers say for the hyperbolic sine key.
  ///
  /// In en, this message translates to:
  /// **'Hyperbolic sine'**
  String get keySinhLabel;

  /// Visible label of the hyperbolic cosine key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'cosh'**
  String get keyCosh;

  /// What screen readers say for the hyperbolic cosine key.
  ///
  /// In en, this message translates to:
  /// **'Hyperbolic cosine'**
  String get keyCoshLabel;

  /// Visible label of the hyperbolic tangent key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'tanh'**
  String get keyTanh;

  /// What screen readers say for the hyperbolic tangent key.
  ///
  /// In en, this message translates to:
  /// **'Hyperbolic tangent'**
  String get keyTanhLabel;

  /// Visible label of the base-10 logarithm key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'log'**
  String get keyLog;

  /// What screen readers say for the base-10 logarithm key.
  ///
  /// In en, this message translates to:
  /// **'Log base 10'**
  String get keyLogLabel;

  /// Visible label of the natural logarithm key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'ln'**
  String get keyLn;

  /// What screen readers say for the natural logarithm key.
  ///
  /// In en, this message translates to:
  /// **'Natural log'**
  String get keyLnLabel;

  /// Visible label of the square root key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'√'**
  String get keySqrt;

  /// What screen readers say for the square root key.
  ///
  /// In en, this message translates to:
  /// **'Square root'**
  String get keySqrtLabel;

  /// Visible label of the cube root key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'∛'**
  String get keyCbrt;

  /// What screen readers say for the cube root key.
  ///
  /// In en, this message translates to:
  /// **'Cube root'**
  String get keyCbrtLabel;

  /// Visible label of the absolute value key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'abs'**
  String get keyAbs;

  /// What screen readers say for the absolute value key.
  ///
  /// In en, this message translates to:
  /// **'Absolute value'**
  String get keyAbsLabel;

  /// Visible label of the square key (2nd of square root).
  ///
  /// In en, this message translates to:
  /// **'x²'**
  String get keySquare;

  /// What screen readers say for the square key.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get keySquareLabel;

  /// Visible label of the cube key (2nd of cube root).
  ///
  /// In en, this message translates to:
  /// **'x³'**
  String get keyCube;

  /// What screen readers say for the cube key.
  ///
  /// In en, this message translates to:
  /// **'Cube'**
  String get keyCubeLabel;

  /// Visible label of the power-of-ten key (2nd of log).
  ///
  /// In en, this message translates to:
  /// **'10ˣ'**
  String get keyPowerOfTen;

  /// What screen readers say for the power-of-ten key.
  ///
  /// In en, this message translates to:
  /// **'Power of ten'**
  String get keyPowerOfTenLabel;

  /// Visible label of the power-of-e key (2nd of ln).
  ///
  /// In en, this message translates to:
  /// **'eˣ'**
  String get keyPowerOfE;

  /// What screen readers say for the power-of-e key.
  ///
  /// In en, this message translates to:
  /// **'Power of e'**
  String get keyPowerOfELabel;

  /// What screen readers say for the ^ key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get keyPowerLabel;

  /// What screen readers say for the ! key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'Factorial'**
  String get keyFactorialLabel;

  /// What screen readers say for the π key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'Pi'**
  String get keyPiLabel;

  /// What screen readers say for the e key in the scientific tray.
  ///
  /// In en, this message translates to:
  /// **'Euler\'s number'**
  String get keyEulerLabel;

  /// Visible label of the angle-mode key when in degrees.
  ///
  /// In en, this message translates to:
  /// **'DEG'**
  String get keyAngleModeDegrees;

  /// What screen readers say for the angle-mode key when in degrees.
  ///
  /// In en, this message translates to:
  /// **'Angle mode, degrees'**
  String get keyAngleModeDegreesLabel;

  /// Visible label of the angle-mode key when in radians.
  ///
  /// In en, this message translates to:
  /// **'RAD'**
  String get keyAngleModeRadians;

  /// What screen readers say for the angle-mode key when in radians.
  ///
  /// In en, this message translates to:
  /// **'Angle mode, radians'**
  String get keyAngleModeRadiansLabel;

  /// Visible label of the 2nd (inverse-function) toggle key.
  ///
  /// In en, this message translates to:
  /// **'2nd'**
  String get keySecond;

  /// What screen readers say for the 2nd toggle key.
  ///
  /// In en, this message translates to:
  /// **'Second function'**
  String get keySecondLabel;

  /// Heading for the trigonometry group in the scientific key tray.
  ///
  /// In en, this message translates to:
  /// **'Trigonometry'**
  String get scientificGroupTrigonometry;

  /// Heading for the hyperbolic-functions group in the scientific key tray.
  ///
  /// In en, this message translates to:
  /// **'Hyperbolic'**
  String get scientificGroupHyperbolic;

  /// Heading for the logarithms-and-powers group in the scientific key tray.
  ///
  /// In en, this message translates to:
  /// **'Logarithms and powers'**
  String get scientificGroupLogarithmsAndPowers;

  /// Heading for the roots group in the scientific key tray.
  ///
  /// In en, this message translates to:
  /// **'Roots'**
  String get scientificGroupRoots;

  /// Heading for the group of remaining scientific keys (abs, factorial, pi, e) in the scientific key tray.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get scientificGroupOther;

  /// What screen readers say for the ± key that flips the typed amount's sign.
  ///
  /// In en, this message translates to:
  /// **'Toggle sign'**
  String get keyToggleSignLabel;

  /// Name of the length conversion category.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get converterCategoryLength;

  /// Name of the weight conversion category.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get converterCategoryWeight;

  /// Name of the temperature conversion category.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get converterCategoryTemperature;

  /// Name of the area conversion category.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get converterCategoryArea;

  /// Name of the volume conversion category.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get converterCategoryVolume;

  /// Name of the time conversion category.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get converterCategoryTime;

  /// Name of the currency conversion category.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get converterCategoryCurrency;

  /// Heading of the sheet listing a category's units to convert between.
  ///
  /// In en, this message translates to:
  /// **'Choose a unit'**
  String get converterUnitPickerTitle;

  /// Label of the text field that filters the unit-picker sheet's list.
  ///
  /// In en, this message translates to:
  /// **'Search units'**
  String get converterUnitSearchLabel;

  /// Shown when a unit-picker search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching units.'**
  String get converterUnitSearchNoMatches;

  /// Label of the card showing the typed amount and its unit.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get converterFromLabel;

  /// Label of the card showing the converted result and its unit.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get converterToLabel;

  /// Tooltip and accessibility label of the button that edits a currency's exchange rate.
  ///
  /// In en, this message translates to:
  /// **'Edit {currency} exchange rate'**
  String converterEditRateTooltip(String currency);

  /// Title of the dialog editing a currency's exchange rate.
  ///
  /// In en, this message translates to:
  /// **'{currency} rate'**
  String converterEditRateTitle(String currency);

  /// Label of the text field where the user types a currency's exchange rate, expressed as units per 1 USD.
  ///
  /// In en, this message translates to:
  /// **'Units per 1 USD'**
  String get converterEditRateLabel;

  /// Button that confirms an edited currency exchange rate.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get converterEditRateSaveAction;

  /// Tooltip and accessibility label of the button that swaps the From and To units.
  ///
  /// In en, this message translates to:
  /// **'Swap units'**
  String get converterSwapTooltip;

  /// Validation message for a financial input field that must be greater than zero.
  ///
  /// In en, this message translates to:
  /// **'Enter a value greater than 0'**
  String get financialErrorMustBePositive;

  /// Validation message for a financial input field that must be zero or greater.
  ///
  /// In en, this message translates to:
  /// **'Enter a value of 0 or more'**
  String get financialErrorMustBeNonNegative;

  /// Validation message for a financial input field that exceeds its sane upper bound.
  ///
  /// In en, this message translates to:
  /// **'Enter at most {max}'**
  String financialErrorTooLarge(int max);

  /// Validation message for a financial input field that must be a whole number of at least 1.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of 1 or more'**
  String get financialErrorMustBePositiveInteger;

  /// Shown in a financial tool's result area while its inputs are incomplete or invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter every amount above to see a result.'**
  String get financialResultPlaceholder;

  /// Name of the EMI (loan instalment) calculator tool.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get financialToolEmi;

  /// Name of the simple interest calculator tool.
  ///
  /// In en, this message translates to:
  /// **'Simple interest'**
  String get financialToolSimpleInterest;

  /// Name of the compound interest calculator tool.
  ///
  /// In en, this message translates to:
  /// **'Compound interest'**
  String get financialToolCompoundInterest;

  /// Name of the GST calculator tool.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get financialToolGst;

  /// Name of the discount calculator tool.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get financialToolDiscount;

  /// Name of the tip calculator tool.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get financialToolTip;

  /// Name of the percentage calculator tool.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get financialToolPercentage;

  /// Label of the EMI tool's loan amount field.
  ///
  /// In en, this message translates to:
  /// **'Loan amount'**
  String get financialEmiPrincipalLabel;

  /// Label of the EMI tool's interest rate field.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (annual)'**
  String get financialEmiRateLabel;

  /// Label of the EMI tool's loan tenure field.
  ///
  /// In en, this message translates to:
  /// **'Tenure'**
  String get financialEmiTenureLabel;

  /// Option label for typing a loan tenure in years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get financialTenureUnitYears;

  /// Option label for typing a loan tenure in months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get financialTenureUnitMonths;

  /// Label of the EMI tool's computed monthly instalment.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI'**
  String get financialEmiMonthlyLabel;

  /// Label of the EMI tool's computed total interest.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get financialEmiTotalInterestLabel;

  /// Label of the EMI tool's computed total payment.
  ///
  /// In en, this message translates to:
  /// **'Total payment'**
  String get financialEmiTotalPaymentLabel;

  /// Legend label for the principal segment of the EMI tool's share-of-whole bar.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get financialEmiChartPrincipalLabel;

  /// Legend label for the interest segment of the EMI tool's share-of-whole bar.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get financialEmiChartInterestLabel;

  /// Label of the simple interest tool's principal field.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get financialSiPrincipalLabel;

  /// Label of the simple interest tool's rate field.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (annual)'**
  String get financialSiRateLabel;

  /// Label of the simple interest tool's time field.
  ///
  /// In en, this message translates to:
  /// **'Time (years)'**
  String get financialSiTimeLabel;

  /// Label of the simple interest tool's computed interest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get financialSiInterestLabel;

  /// Label of the simple interest tool's computed total amount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get financialSiTotalLabel;

  /// Label of the compound interest tool's principal field.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get financialCiPrincipalLabel;

  /// Label of the compound interest tool's rate field.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (annual)'**
  String get financialCiRateLabel;

  /// Label of the compound interest tool's time field.
  ///
  /// In en, this message translates to:
  /// **'Time (years)'**
  String get financialCiTimeLabel;

  /// Label of the compound interest tool's compounding frequency choice.
  ///
  /// In en, this message translates to:
  /// **'Compounding'**
  String get financialCiFrequencyLabel;

  /// Option label for interest compounding once a year.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get financialCiFrequencyAnnual;

  /// Option label for interest compounding twice a year.
  ///
  /// In en, this message translates to:
  /// **'Semi-annual'**
  String get financialCiFrequencySemiAnnual;

  /// Option label for interest compounding four times a year.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get financialCiFrequencyQuarterly;

  /// Option label for interest compounding twelve times a year.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get financialCiFrequencyMonthly;

  /// Label of the compound interest tool's computed interest.
  ///
  /// In en, this message translates to:
  /// **'Interest earned'**
  String get financialCiInterestLabel;

  /// Label of the compound interest tool's computed total amount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get financialCiTotalLabel;

  /// Label of the GST tool's amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get financialGstAmountLabel;

  /// Label of the GST tool's rate field.
  ///
  /// In en, this message translates to:
  /// **'GST rate'**
  String get financialGstRateLabel;

  /// Label of the GST tool's exclusive/inclusive choice.
  ///
  /// In en, this message translates to:
  /// **'GST is'**
  String get financialGstModeLabel;

  /// Option label: the entered amount excludes GST, which is added on top.
  ///
  /// In en, this message translates to:
  /// **'Added to amount'**
  String get financialGstModeExclusive;

  /// Option label: the entered amount already includes GST.
  ///
  /// In en, this message translates to:
  /// **'Already included'**
  String get financialGstModeInclusive;

  /// Label of the GST tool's intra-state/inter-state choice.
  ///
  /// In en, this message translates to:
  /// **'Supply type'**
  String get financialGstSupplyLabel;

  /// Option label: a supply within the same state, shown as CGST+SGST.
  ///
  /// In en, this message translates to:
  /// **'Intra-state (CGST+SGST)'**
  String get financialGstSupplyIntraState;

  /// Option label: a supply across states, shown as IGST.
  ///
  /// In en, this message translates to:
  /// **'Inter-state (IGST)'**
  String get financialGstSupplyInterState;

  /// Label of the GST tool's computed base (pre-tax) amount.
  ///
  /// In en, this message translates to:
  /// **'Base amount'**
  String get financialGstBaseLabel;

  /// Label of the GST tool's computed CGST (central GST) share.
  ///
  /// In en, this message translates to:
  /// **'CGST'**
  String get financialGstCgstLabel;

  /// Label of the GST tool's computed SGST (state GST) share.
  ///
  /// In en, this message translates to:
  /// **'SGST'**
  String get financialGstSgstLabel;

  /// Label of the GST tool's computed IGST (integrated GST) amount.
  ///
  /// In en, this message translates to:
  /// **'IGST'**
  String get financialGstIgstLabel;

  /// Label of the GST tool's computed total amount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get financialGstTotalLabel;

  /// Legend label for the GST segment of the GST tool's share-of-whole bar.
  ///
  /// In en, this message translates to:
  /// **'GST amount'**
  String get financialGstAmountResultLabel;

  /// Label of the discount tool's price field.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get financialDiscountPriceLabel;

  /// Label of the discount tool's discount percentage field.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get financialDiscountPercentLabel;

  /// Label of the discount tool's computed final price.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get financialDiscountFinalPriceLabel;

  /// Label of the discount tool's computed discount amount.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get financialDiscountAmountLabel;

  /// Label of the tip tool's bill amount field.
  ///
  /// In en, this message translates to:
  /// **'Bill amount'**
  String get financialTipBillLabel;

  /// Label of the tip tool's tip percentage field.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get financialTipPercentLabel;

  /// Label of the tip tool's split-count field.
  ///
  /// In en, this message translates to:
  /// **'Split between'**
  String get financialTipSplitLabel;

  /// Label of the tip tool's computed per-person share.
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get financialTipPerPersonLabel;

  /// Label of the tip tool's computed tip amount.
  ///
  /// In en, this message translates to:
  /// **'Tip amount'**
  String get financialTipAmountLabel;

  /// Label of the tip tool's computed total (bill plus tip).
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get financialTipTotalLabel;

  /// Label of the percentage tool's percentage field, in "X% of Y" mode.
  ///
  /// In en, this message translates to:
  /// **'Percentage (%)'**
  String get financialPercentOfXLabel;

  /// Label of the percentage tool's base amount field, in "X% of Y" mode.
  ///
  /// In en, this message translates to:
  /// **'Of this amount'**
  String get financialPercentOfYLabel;

  /// Label of the percentage tool's part-amount field, in "X is what % of Y" mode.
  ///
  /// In en, this message translates to:
  /// **'This amount'**
  String get financialPercentWhatXLabel;

  /// Label of the percentage tool's whole-amount field, in "X is what % of Y" mode.
  ///
  /// In en, this message translates to:
  /// **'Out of this total'**
  String get financialPercentWhatYLabel;

  /// Label of the percentage tool's percentage field, in "increase/decrease Y by X%" mode.
  ///
  /// In en, this message translates to:
  /// **'Percentage (%)'**
  String get financialPercentChangeXLabel;

  /// Label of the percentage tool's starting-amount field, in "increase/decrease Y by X%" mode.
  ///
  /// In en, this message translates to:
  /// **'Starting amount'**
  String get financialPercentChangeYLabel;

  /// Option label for the "what is X% of Y" percentage operation.
  ///
  /// In en, this message translates to:
  /// **'X% of Y'**
  String get financialPercentOpPercentOf;

  /// Option label for the "X is what percentage of Y" percentage operation.
  ///
  /// In en, this message translates to:
  /// **'X is what % of Y'**
  String get financialPercentOpWhatPercent;

  /// Option label for the "increase or decrease Y by X percent" percentage operation.
  ///
  /// In en, this message translates to:
  /// **'Increase/decrease Y by X%'**
  String get financialPercentOpChangeBy;

  /// Label of the percentage tool's operation choice.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get financialPercentOperationLabel;

  /// Option label for increasing an amount by a percentage.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get financialPercentDirectionIncrease;

  /// Option label for decreasing an amount by a percentage.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get financialPercentDirectionDecrease;

  /// Label of the percentage tool's computed result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get financialPercentResultLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
