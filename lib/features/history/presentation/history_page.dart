import 'package:flutter/material.dart';
import 'package:smart_calculator/features/history/presentation/history_placeholder.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The history page, pushed on windows that have no history panel.
class HistoryPage extends StatelessWidget {
  /// Creates the history page.
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).historyTitle)),
    body: const SafeArea(top: false, child: HistoryPlaceholder()),
  );
}
