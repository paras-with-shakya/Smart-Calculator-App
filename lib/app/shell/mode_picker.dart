import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/modes/mode_grid.dart';
import 'package:smart_calculator/core/widgets/app_bottom_sheet.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The mode pill for compact windows: shows the current mode and opens the
/// mode sheet.
class ModePickerButton extends ConsumerWidget {
  /// Creates the mode pill.
  const ModePickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(currentModeProvider);
    return Tooltip(
      message: l10n.changeModeTooltip,
      child: AppButton(
        label: mode.label(l10n),
        variant: AppButtonVariant.secondary,
        trailingIcon: Icons.arrow_drop_down,
        onPressed: () => showAppBottomSheet<void>(
          context: context,
          title: l10n.modeSheetTitle,
          builder: (_) => const _CurrentModeGrid(),
        ),
      ),
    );
  }
}

/// The mode grid of the sheet: the current mode is selected; choosing a tile
/// switches to it and closes the sheet.
class _CurrentModeGrid extends ConsumerWidget {
  const _CurrentModeGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModeGrid(
    selected: ref.watch(currentModeProvider),
    onSelected: (mode) {
      ref.read(currentModeProvider.notifier).select(mode);
      Navigator.of(context).pop();
    },
  );
}
