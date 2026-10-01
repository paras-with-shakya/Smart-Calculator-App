import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/app_bottom_sheet.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/features/programmer/application/programmer_notifier.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Two buttons: the word size and signed or unsigned. Each opens a sheet
/// with the choice, so the screen keeps a single 48 dp row for both and the
/// keypad stays on screen.
class ProgrammerWordControls extends ConsumerWidget {
  /// Creates the controls.
  const ProgrammerWordControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final word = ref.watch(programmerProvider.select((s) => s.word));
    final notifier = ref.read(programmerProvider.notifier);
    final kind = word.signed ? l10n.programmerSigned : l10n.programmerUnsigned;

    Future<void> chooseSize() async {
      final bits = await showAppBottomSheet<int>(
        context: context,
        title: l10n.programmerWordSizeTitle,
        builder: (sheetContext) => AppChoiceGroup<int>(
          options: [
            for (final size in ProgrammerWord.supportedBits)
              AppChoice(value: size, label: '$size'),
          ],
          selected: word.bits,
          onChanged: (size) => Navigator.of(sheetContext).pop(size),
        ),
      );
      if (bits != null) notifier.setBits(bits);
    }

    Future<void> chooseSignedness() async {
      final signed = await showAppBottomSheet<bool>(
        context: context,
        title: l10n.programmerSignednessTitle,
        builder: (sheetContext) => AppChoiceGroup<bool>(
          options: [
            AppChoice(value: true, label: l10n.programmerSigned),
            AppChoice(value: false, label: l10n.programmerUnsigned),
          ],
          selected: word.signed,
          onChanged: (value) => Navigator.of(sheetContext).pop(value),
        ),
      );
      if (signed != null) notifier.setSigned(signed: signed);
    }

    final sizeButton = Semantics(
      label: l10n.programmerWordSizeSemantics(word.bits),
      button: true,
      onTap: chooseSize,
      excludeSemantics: true,
      child: AppButton(
        label: l10n.programmerWordSizeButton(word.bits),
        variant: AppButtonVariant.secondary,
        trailingIcon: Icons.arrow_drop_down,
        expand: true,
        onPressed: chooseSize,
      ),
    );

    final signednessButton = Semantics(
      label: l10n.programmerSignednessSemantics(kind),
      button: true,
      onTap: chooseSignedness,
      excludeSemantics: true,
      child: AppButton(
        label: kind,
        variant: AppButtonVariant.secondary,
        trailingIcon: Icons.arrow_drop_down,
        expand: true,
        onPressed: chooseSignedness,
      ),
    );

    // Side by side, unless the text is so large that a label would break
    // inside a half-width button.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return stacked
        ? Column(
            crossAxisAlignment: .stretch,
            children: [
              sizeButton,
              const SizedBox(height: AppSpacing.sm),
              signednessButton,
            ],
          )
        : Row(
            children: [
              Expanded(child: sizeButton),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: signednessButton),
            ],
          );
  }
}
