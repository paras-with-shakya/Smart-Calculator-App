import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/shell/mode_navigation_rail.dart';
import 'package:smart_calculator/app/shell/shell_header.dart';
import 'package:smart_calculator/core/layout/window_size_class.dart';
import 'package:smart_calculator/core/widgets/status_views.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_view.dart';
import 'package:smart_calculator/features/calculator/presentation/scientific_calculator_view.dart';
import 'package:smart_calculator/features/converter/presentation/converter_view.dart';
import 'package:smart_calculator/features/history/presentation/history_panel.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The adaptive frame around the current mode.
///
/// - Compact windows (phones in portrait): a top bar with the mode pill.
///   History and settings open as pages. There is no bottom navigation
///   (DEC-012).
/// - Medium windows: a navigation rail of modes.
/// - Expanded windows: the rail plus a history side panel, unless the
///   window is shorter than [historyPanelMinHeight] (a phone in landscape),
///   where the panel would squeeze the calculator. History then opens as a
///   page, as on medium windows.
class AppShell extends StatelessWidget {
  /// Creates the shell.
  const AppShell({super.key});

  /// The shortest window that shows the history panel: Material's compact
  /// height class ends here.
  static const double historyPanelMinHeight = 480;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return switch (WindowSizeClass.fromWidth(size.width)) {
      WindowSizeClass.compact => const _CompactShell(),
      WindowSizeClass.medium => const _RailShell(showHistoryPanel: false),
      WindowSizeClass.expanded => _RailShell(
        showHistoryPanel: size.height >= historyPanelMinHeight,
      ),
    };
  }
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

/// The current mode's content. Modes not built yet show an empty state
/// until their phase (docs/ROADMAP.md).
class _CurrentModeView extends ConsumerWidget {
  const _CurrentModeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(currentModeProvider)) {
        CalculatorMode.basic => const CalculatorView(),
        CalculatorMode.scientific => const ScientificCalculatorView(),
        CalculatorMode.converter => const ConverterView(),
        final mode => EmptyState(
          icon: mode.icon,
          message: AppLocalizations.of(context).modeNotAvailableYet,
        ),
      };
}
