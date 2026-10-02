import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/navigation/app_navigator.dart';
import 'package:smart_calculator/app/navigation/app_route.dart';
import 'package:smart_calculator/app/shell/mode_picker.dart';
import 'package:smart_calculator/core/widgets/app_header.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The shell's top bar: the current mode, plus the history and settings
/// actions.
class ShellHeader extends ConsumerWidget implements PreferredSizeWidget {
  /// Creates the top bar.
  const ShellHeader({
    super.key,
    required this.showModePicker,
    required this.showHistoryAction,
  });

  /// Whether the mode is shown as the mode pill (compact windows) rather than
  /// a plain title (the navigation rail picks the mode instead).
  final bool showModePicker;

  /// Whether to show the history action. It is hidden when a history panel
  /// is already on screen.
  final bool showHistoryAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(currentModeProvider);
    return AppHeader(
      title: showModePicker ? const ModePickerButton() : Text(mode.label(l10n)),
      actions: [
        if (showHistoryAction)
          AppIconButton(
            icon: Icons.history_outlined,
            tooltip: l10n.historyTitle,
            onPressed: () => context.pushRoute<void>(const HistoryRoute()),
          ),
        AppIconButton(
          icon: Icons.settings_outlined,
          tooltip: l10n.settingsTitle,
          onPressed: () => context.pushRoute<void>(const SettingsRoute()),
        ),
      ],
    );
  }
}
