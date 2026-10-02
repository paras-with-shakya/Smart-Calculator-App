import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/features/converter/application/converter_notifier.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The icon shown for [category].
IconData iconFor(ConversionCategoryId category) => switch (category) {
  ConversionCategoryId.length => Icons.straighten,
  ConversionCategoryId.weight => Icons.scale,
  ConversionCategoryId.temperature => Icons.thermostat,
  ConversionCategoryId.area => Icons.crop_square,
  ConversionCategoryId.volume => Icons.local_drink_outlined,
  ConversionCategoryId.time => Icons.schedule,
  ConversionCategoryId.currency => Icons.currency_exchange,
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

/// A wrapping grid of tiles, one per [ConversionCategoryId], the current
/// one tinted with [AppCard.selected] — not `AppChoiceGroup`, which falls
/// back to a tall vertical radio list once labels stop fitting a segmented
/// row (likely with this many options on a phone width), losing the icon
/// grid this app's own gallery already uses for a similar choice.
class CategoryPicker extends ConsumerWidget {
  /// Creates the picker.
  const CategoryPicker({super.key});

  static const double _tileWidth = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(
      converterProvider.select((state) => state.category),
    );
    final notifier = ref.read(converterProvider.notifier);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in ConversionCategoryId.values)
          SizedBox(
            width: _tileWidth,
            child: AppCard(
              selected: category == current,
              onTap: () {
                ref.read(keyFeedbackProvider).select();
                notifier.selectCategory(category);
              },
              child: Column(
                children: [
                  Icon(iconFor(category)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    labelFor(l10n, category),
                    textAlign: .center,
                    style: AppTypography.of(context).label,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
