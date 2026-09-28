import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/modes/current_mode_notifier.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
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
      child: FilledButton.tonal(
        onPressed: () => _showModeSheet(context),
        child: Row(
          mainAxisSize: .min,
          children: [
            Flexible(child: Text(mode.label(l10n), overflow: .ellipsis)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<void> _showModeSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _ModeSheet(),
      );
}

/// Lists every mode; choosing one switches to it and closes the sheet.
class _ModeSheet extends ConsumerWidget {
  const _ModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(currentModeProvider);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Semantics(
              header: true,
              child: Text(
                l10n.modeSheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final mode in CalculatorMode.values)
            ListTile(
              leading: Icon(mode.icon),
              title: Text(mode.label(l10n)),
              selected: mode == current,
              trailing: mode == current ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(currentModeProvider.notifier).select(mode);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
