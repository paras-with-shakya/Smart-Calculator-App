import 'package:flutter/material.dart';
import 'package:smart_calculator/core/widgets/result_row.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Shown in place of a tool's result card while its inputs are incomplete
/// or invalid.
class FinancialResultPlaceholder extends StatelessWidget {
  const FinancialResultPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => ResultPlaceholder(
    message: AppLocalizations.of(context).financialResultPlaceholder,
  );
}
