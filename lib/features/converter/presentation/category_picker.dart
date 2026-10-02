import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_motion.dart';
import 'package:smart_calculator/app/theme/app_sizing.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/features/converter/application/converter_notifier.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The icon shown for [category].
IconData iconFor(ConversionCategoryId category) => switch (category) {
  ConversionCategoryId.length => Icons.straighten_outlined,
  ConversionCategoryId.weight => Icons.scale_outlined,
  ConversionCategoryId.temperature => Icons.thermostat_outlined,
  ConversionCategoryId.area => Icons.crop_square_outlined,
  ConversionCategoryId.volume => Icons.local_drink_outlined,
  ConversionCategoryId.time => Icons.schedule_outlined,
  ConversionCategoryId.currency => Icons.currency_exchange_outlined,
};

/// The label shown for [category].
String labelFor(AppLocalizations l10n, ConversionCategoryId category) =>
    switch (category) {
      ConversionCategoryId.length => l10n.converterCategoryLength,
      ConversionCategoryId.weight => l10n.converterCategoryWeight,
      ConversionCategoryId.temperature => l10n.converterCategoryTemperature,
      ConversionCategoryId.area => l10n.converterCategoryArea,
      ConversionCategoryId.volume => l10n.converterCategoryVolume,
      ConversionCategoryId.time => l10n.converterCategoryTime,
      ConversionCategoryId.currency => l10n.converterCategoryCurrency,
    };

/// One row of chips, one per [ConversionCategoryId], that scrolls sideways;
/// the current one is tinted with [AppCard.selected] and kept in view.
///
/// A row rather than the earlier grid of tiles (Phase 11, the user's
/// choice): the grid took three rows on a phone, which pushed the bottom
/// keypad rows off the screen. Each chip is as wide as its label, so a label
/// is never broken (Known Issues #19), at any text size.
class CategoryPicker extends ConsumerStatefulWidget {
  /// Creates the picker.
  const CategoryPicker({super.key});

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker> {
  final Map<ConversionCategoryId, GlobalKey> _chipKeys = {
    for (final category in ConversionCategoryId.values) category: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    // The saved category may be at the end of the row, out of view.
    _revealSelected(animate: false);
  }

  /// Scrolls the selected chip into view after this frame.
  void _revealSelected({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chip =
          _chipKeys[ref.read(converterProvider).category]!.currentContext;
      if (chip == null) return;
      Scrollable.ensureVisible(
        chip,
        alignment: 0.5,
        duration: animate
            ? AppMotion.durationOf(context, AppMotion.medium)
            : Duration.zero,
        curve: AppMotion.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(
      converterProvider.select((state) => state.category),
    );
    ref.listen(
      converterProvider.select((state) => state.category),
      (_, _) => _revealSelected(animate: true),
    );
    final notifier = ref.read(converterProvider.notifier);
    final labelStyle = AppTypography.of(context).label;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, category) in ConversionCategoryId.values.indexed)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: index == 0 ? 0 : AppSpacing.sm,
              ),
              child: ConstrainedBox(
                key: _chipKeys[category],
                constraints: BoxConstraints(
                  minHeight: AppSizing.minTarget(context),
                ),
                child: AppCard(
                  selected: category == current,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  onTap: () {
                    ref.read(keyFeedbackProvider).select();
                    notifier.selectCategory(category);
                  },
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Icon(iconFor(category)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(labelFor(l10n, category), style: labelStyle),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
