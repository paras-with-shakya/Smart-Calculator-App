import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/app_bottom_sheet.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/converter/domain/unit.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Opens a searchable sheet listing [category]'s units, [currentUnitId]
/// marked selected. Returns the picked unit id, or null if dismissed
/// without picking one.
Future<String?> showUnitPicker(
  BuildContext context, {
  required ConversionCategory category,
  required String currentUnitId,
}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<String>(
    context: context,
    title: l10n.converterUnitPickerTitle,
    builder: (sheetContext) =>
        _UnitPickerContent(category: category, currentUnitId: currentUnitId),
  );
}

class _UnitPickerContent extends ConsumerStatefulWidget {
  const _UnitPickerContent({
    required this.category,
    required this.currentUnitId,
  });

  final ConversionCategory category;
  final String currentUnitId;

  @override
  ConsumerState<_UnitPickerContent> createState() => _UnitPickerContentState();
}

class _UnitPickerContentState extends ConsumerState<_UnitPickerContent> {
  final TextEditingController _query = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<ConversionUnit> get _filtered {
    final query = _filter.trim().toLowerCase();
    if (query.isEmpty) return widget.category.units;
    return widget.category.units
        .where((unit) => unit.symbol.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = _filtered;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        AppTextField(
          label: l10n.converterUnitSearchLabel,
          controller: _query,
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (units.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(l10n.converterUnitSearchNoMatches),
          )
        else
          for (final (index, unit) in units.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.xs),
            AppCard(
              selected: unit.id == widget.currentUnitId,
              onTap: () {
                ref.read(keyFeedbackProvider).select();
                Navigator.of(context).pop(unit.id);
              },
              child: Row(
                children: [
                  Expanded(child: Text(unit.symbol)),
                  if (unit.id == widget.currentUnitId)
                    const Icon(Icons.check, size: 20),
                ],
              ),
            ),
          ],
      ],
    );
  }
}
