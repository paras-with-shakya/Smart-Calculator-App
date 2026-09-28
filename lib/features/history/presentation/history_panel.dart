import 'package:flutter/material.dart';
import 'package:smart_calculator/features/history/presentation/history_placeholder.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// History shown beside the current mode on expanded windows.
class HistoryPanel extends StatelessWidget {
  /// Creates the history panel.
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppBar(
        title: Text(AppLocalizations.of(context).historyTitle),
        automaticallyImplyLeading: false,
        primary: false,
      ),
      const Expanded(child: HistoryPlaceholder()),
    ],
  );
}
