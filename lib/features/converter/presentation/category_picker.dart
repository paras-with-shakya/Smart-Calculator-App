import 'dart:math' as math;

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
///
/// Every tile is the same width: at least [_minTileWidth], and wide enough
/// for the longest label on one line at the current text size, so a label
/// ("Temperature") is never broken mid-word, at any text size.
class CategoryPicker extends ConsumerWidget {
  /// Creates the picker.
  const CategoryPicker({super.key});

  static const double _minTileWidth = 96;

  /// Side padding of a tile. Narrower than [AppCard]'s default, so that the
  /// longest label at 100% text still leaves three tiles to a row on a
  /// 360 dp phone.
  static const EdgeInsets _tilePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.md,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(
      converterProvider.select((state) => state.category),
    );
    final notifier = ref.read(converterProvider.notifier);
    final labelStyle = AppTypography.of(context).label;
    final widest = _widestLabel(
      [
        for (final category in ConversionCategoryId.values)
          labelFor(l10n, category),
      ],
      labelStyle,
      MediaQuery.textScalerOf(context),
      Directionality.of(context),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitting = math.max(
          _minTileWidth,
          widest.ceilToDouble() + _tilePadding.horizontal,
        );
        // Never wider than the space there is; a label then breaks only if
        // even a whole row cannot hold it.
        final tileWidth = constraints.hasBoundedWidth
            ? math.min(fitting, constraints.maxWidth)
            : fitting;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final category in ConversionCategoryId.values)
              SizedBox(
                width: tileWidth,
                child: AppCard(
                  selected: category == current,
                  padding: _tilePadding,
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
                        style: labelStyle,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// The width of the widest of [labels] on one line.
  static double _widestLabel(
    List<String> labels,
    TextStyle style,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    var widest = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    return widest;
  }
}
