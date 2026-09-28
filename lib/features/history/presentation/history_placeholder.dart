import 'package:flutter/material.dart';
import 'package:smart_calculator/core/widgets/placeholder_view.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Stands in for the calculation history until Phase 4 implements it.
class HistoryPlaceholder extends StatelessWidget {
  /// Creates the history placeholder.
  const HistoryPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderView(
    icon: Icons.history,
    message: AppLocalizations.of(context).historyNotAvailableYet,
  );
}
