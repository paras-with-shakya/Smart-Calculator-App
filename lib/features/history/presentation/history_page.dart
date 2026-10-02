import 'package:flutter/material.dart';
import 'package:smart_calculator/core/layout/layout_limits.dart';
import 'package:smart_calculator/core/widgets/app_header.dart';
import 'package:smart_calculator/features/history/presentation/history_content.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The history page, pushed on windows that have no history panel. On a
/// wide window its content is a centred column, as on every other screen,
/// so an entry's actions stay next to its text.
class HistoryPage extends StatelessWidget {
  /// Creates the history page.
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppHeader(title: Text(AppLocalizations.of(context).historyTitle)),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: LayoutLimits.maxContentWidth,
          ),
          child: const HistoryContent(),
        ),
      ),
    ),
  );
}
