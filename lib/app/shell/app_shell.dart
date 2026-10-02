import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/shell/mode_navigation_rail.dart';
import 'package:smart_calculator/app/shell/shell_header.dart';
import 'package:smart_calculator/app/theme/app_motion.dart';
import 'package:smart_calculator/core/layout/layout_limits.dart';
import 'package:smart_calculator/core/layout/window_size_class.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_view.dart';
import 'package:smart_calculator/features/calculator/presentation/scientific_calculator_view.dart';
import 'package:smart_calculator/features/converter/presentation/converter_view.dart';
import 'package:smart_calculator/features/date_calculator/presentation/date_calculator_view.dart';
import 'package:smart_calculator/features/financial/presentation/financial_view.dart';
import 'package:smart_calculator/features/history/presentation/history_panel.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_view.dart';

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
  static const double historyPanelMinHeight = LayoutLimits.compactHeight;

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

/// The current mode's content. Switching modes cross-fades the two screens
/// ([AppMotion.medium]; instant when the platform asks for reduced motion).
class _CurrentModeView extends ConsumerWidget {
  const _CurrentModeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(currentModeProvider);
    return AnimatedSwitcher(
      duration: AppMotion.durationOf(context, AppMotion.medium),
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      layoutBuilder: _layout,
      child: KeyedSubtree(
        key: ValueKey(mode),
        child: switch (mode) {
          CalculatorMode.basic => const CalculatorView(),
          CalculatorMode.scientific => const ScientificCalculatorView(),
          CalculatorMode.converter => const ConverterView(),
          CalculatorMode.finance => const FinancialView(),
          CalculatorMode.date => const DateCalculatorView(),
          CalculatorMode.programmer => const ProgrammerView(),
        },
      ),
    );
  }

  /// Both screens fill the space (as the one screen did before), and the one
  /// fading out can no longer be tapped or read by a screen reader. Every
  /// child gets the same wrapper, keyed like the child, so a screen keeps its
  /// state when it moves from incoming to outgoing.
  static Widget _layout(Widget? current, List<Widget> previous) => Stack(
    fit: StackFit.expand,
    children: [
      for (final child in previous) _wrap(child, outgoing: true),
      if (current != null) _wrap(current, outgoing: false),
    ],
  );

  static Widget _wrap(Widget child, {required bool outgoing}) => IgnorePointer(
    key: child.key,
    ignoring: outgoing,
    child: ExcludeSemantics(excluding: outgoing, child: child),
  );
}
