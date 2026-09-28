import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Navigation rail listing every mode, for medium and expanded windows.
///
/// It scrolls when the window is too short to show every destination, such
/// as a phone in landscape.
class ModeNavigationRail extends ConsumerWidget {
  /// Creates the mode rail.
  const ModeNavigationRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(currentModeProvider);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: current.index,
              onDestinationSelected: (index) => ref
                  .read(currentModeProvider.notifier)
                  .select(CalculatorMode.values[index]),
              labelType: .all,
              destinations: [
                for (final mode in CalculatorMode.values)
                  NavigationRailDestination(
                    icon: Icon(mode.icon),
                    label: Text(mode.label(l10n)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
