import 'package:flutter/material.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// How each [CalculatorMode] is presented: its icon and translated name.
extension CalculatorModePresentation on CalculatorMode {
  /// Icon shown in the mode sheet, the navigation rail and placeholders:
  /// the outlined style, like every other icon in the app.
  IconData get icon => switch (this) {
    CalculatorMode.basic => Icons.calculate_outlined,
    CalculatorMode.scientific => Icons.functions_outlined,
    CalculatorMode.programmer => Icons.data_object_outlined,
    CalculatorMode.finance => Icons.savings_outlined,
    CalculatorMode.converter => Icons.swap_horiz_outlined,
    CalculatorMode.date => Icons.calendar_month_outlined,
  };

  /// [icon] filled in, for the selected destination of the navigation rail
  /// (Material's convention for a selected item).
  IconData get selectedIcon => switch (this) {
    CalculatorMode.basic => Icons.calculate,
    CalculatorMode.scientific => Icons.functions,
    CalculatorMode.programmer => Icons.data_object,
    CalculatorMode.finance => Icons.savings,
    CalculatorMode.converter => Icons.swap_horiz,
    CalculatorMode.date => Icons.calendar_month,
  };

  /// The mode's name in the current language.
  String label(AppLocalizations l10n) => switch (this) {
    CalculatorMode.basic => l10n.modeBasic,
    CalculatorMode.scientific => l10n.modeScientific,
    CalculatorMode.programmer => l10n.modeProgrammer,
    CalculatorMode.finance => l10n.modeFinance,
    CalculatorMode.converter => l10n.modeConverter,
    CalculatorMode.date => l10n.modeDate,
  };
}
