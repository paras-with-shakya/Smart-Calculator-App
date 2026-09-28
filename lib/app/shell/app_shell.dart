import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/shell/mode_navigation_rail.dart';
import 'package:smart_calculator/app/shell/shell_header.dart';
import 'package:smart_calculator/core/layout/window_size_class.dart';
import 'package:smart_calculator/core/widgets/placeholder_view.dart';
import 'package:smart_calculator/features/history/presentation/history_panel.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The adaptive frame around the current mode.
///
/// - Compact windows (phones in portrait): a top bar with the mode pill.
///   History and settings open as pages. There is no bottom navigation
///   (DEC-012).
/// - Medium windows: a navigation rail of modes.
/// - Expanded windows: the rail plus a history side panel.
class AppShell extends StatelessWidget {
  /// Creates the shell.
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) =>
      switch (WindowSizeClass.fromWidth(MediaQuery.sizeOf(context).width)) {
        WindowSizeClass.compact => const _CompactShell(),
        WindowSizeClass.medium => const _RailShell(showHistoryPanel: false),
        WindowSizeClass.expanded => const _RailShell(showHistoryPanel: true),
      };
}

class _CompactShell extends StatelessWidget {
  const _CompactShell();

  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: ShellHeader(showModePicker: true, showHistoryAction: true),
    body: SafeArea(top: false, child: _CurrentModeView()),
  );
}

class _RailShell extends StatelessWidget {
  const _RailShell({required this.showHistoryPanel});

  final bool showHistoryPanel;

  static const double _dividerWidth = 1;
  static const double _historyPanelWidth = 320;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          const ModeNavigationRail(),
          const VerticalDivider(width: _dividerWidth),
          Expanded(
            child: Column(
              children: [
                ShellHeader(
                  showModePicker: false,
                  showHistoryAction: !showHistoryPanel,
                ),
                const Expanded(child: _CurrentModeView()),
              ],
            ),
          ),
          if (showHistoryPanel) ...[
            const VerticalDivider(width: _dividerWidth),
            const SizedBox(width: _historyPanelWidth, child: HistoryPanel()),
          ],
        ],
      ),
    ),
  );
}

/// The current mode's content. Every mode is a placeholder until its phase
/// is implemented (docs/ROADMAP.md).
class _CurrentModeView extends ConsumerWidget {
  const _CurrentModeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(currentModeProvider);
    return PlaceholderView(
      icon: mode.icon,
      message: AppLocalizations.of(context).modeNotAvailableYet,
    );
  }
}
