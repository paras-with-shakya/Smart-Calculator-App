import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_sizing.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/layout/layout_limits.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/features/converter/application/converter_notifier.dart';
import 'package:smart_calculator/features/converter/presentation/category_picker.dart';
import 'package:smart_calculator/features/converter/presentation/converter_card.dart';
import 'package:smart_calculator/features/converter/presentation/converter_keypad.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The unit converter: category picker, From/To cards with a swap button,
/// and a compact numeric keypad.
///
/// **Portrait:** one column. With the category picker a single row of chips
/// (Phase 11), the cards and the whole keypad fit a 360 × 800 dp phone
/// without scrolling; at larger text sizes the column scrolls, so nothing
/// overflows.
/// **Landscape:** the category picker and cards on the left, the keypad on
/// the right, so a short landscape phone doesn't have to squeeze both into
/// one column.
class ConverterView extends StatelessWidget {
  /// Creates the converter screen.
  const ConverterView({super.key});

  /// The widest the content column gets.
  static const double maxContentWidth = LayoutLimits.maxContentWidth;

  /// The share of the width the landscape keypad takes.
  static const double landscapeKeypadWidthFraction = 0.5;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final keypadHeight = _keypadHeight(context);
      return constraints.maxWidth > constraints.maxHeight
          ? _landscape(constraints, keypadHeight)
          : _portrait(keypadHeight);
    },
  );

  Widget _portrait(double keypadHeight) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Column(
          children: [
            const CategoryPicker(),
            const SizedBox(height: AppSpacing.md),
            const _AmountCards(),
            const SizedBox(height: AppSpacing.md),
            SizedBox(height: keypadHeight, child: const ConverterKeypad()),
          ],
        ),
      ),
    ),
  );

  Widget _landscape(BoxConstraints constraints, double keypadHeight) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            const Expanded(
              child: Column(
                mainAxisSize: .min,
                children: [
                  CategoryPicker(),
                  SizedBox(height: AppSpacing.md),
                  _AmountCards(),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
              width: math.min(
                constraints.maxWidth * landscapeKeypadWidthFraction,
                LayoutLimits.maxContentWidth,
              ),
              height: keypadHeight,
              child: const ConverterKeypad(),
            ),
          ],
        ),
      );

  /// Four key rows tall, at a touch-friendly 56dp each (above the 48dp
  /// minimum), scaled with the system's text size the same way the rows
  /// themselves grow.
  double _keypadHeight(BuildContext context) {
    const rows = 4;
    const rowHeight = 56.0;
    final scaledRow =
        MediaQuery.textScalerOf(context).scale(rowHeight) *
        AppSizing.of(context);
    return rows * scaledRow + (rows - 1) * AppSpacing.sm;
  }
}

class _AmountCards extends ConsumerWidget {
  const _AmountCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(converterProvider.notifier);

    return Column(
      children: [
        const ConverterCard(role: ConverterCardRole.from),
        const SizedBox(height: AppSpacing.sm),
        AppIconButton(
          icon: Icons.swap_horiz_outlined,
          tooltip: l10n.converterSwapTooltip,
          variant: AppIconButtonVariant.tonal,
          onPressed: () {
            ref.read(keyFeedbackProvider).select();
            notifier.swap();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        const ConverterCard(role: ConverterCardRole.to),
      ],
    );
  }
}
