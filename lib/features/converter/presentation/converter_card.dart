import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/features/converter/application/converter_notifier.dart';
import 'package:smart_calculator/features/converter/domain/conversion_category.dart';
import 'package:smart_calculator/features/converter/domain/number_entry_buffer.dart';
import 'package:smart_calculator/features/converter/presentation/unit_names.dart';
import 'package:smart_calculator/features/converter/presentation/unit_picker_sheet.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Which side of the conversion a [ConverterCard] shows.
enum ConverterCardRole {
  /// The typed amount and its unit.
  from,

  /// The computed result and its unit.
  to,
}

/// A card showing one side of the conversion: the amount, and its unit
/// (tapping it opens the unit-picker sheet). For a non-USD currency unit,
/// also a small button to edit that currency's exchange rate.
class ConverterCard extends ConsumerWidget {
  /// Creates the card for [role].
  const ConverterCard({super.key, required this.role});

  /// Which side this card shows.
  final ConverterCardRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final format = ref.watch(numberFormatProvider);
    final state = ref.watch(converterProvider);
    final notifier = ref.read(converterProvider.notifier);
    final isFrom = role == ConverterCardRole.from;
    final unitId = isFrom ? state.fromUnitId : state.toUnitId;
    final unit = state.table.unit(unitId);
    final amountText = isFrom
        ? _formatAmount(format, state.amount)
        : _formatResult(format, state.result);
    final amountValue = (isFrom ? state.amount.value : state.result) ?? 0;
    final showEditRate =
        state.category == ConversionCategoryId.currency && unitId != 'usd';

    return AppCard(
      onTap: () async {
        final picked = await showUnitPicker(
          context,
          category: state.table,
          currentUnitId: unitId,
        );
        if (picked == null) return;
        ref.read(keyFeedbackProvider).select();
        if (isFrom) {
          notifier.selectFromUnit(picked);
        } else {
          notifier.selectToUnit(picked);
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  isFrom ? l10n.converterFromLabel : l10n.converterToLabel,
                  style: AppTypography.of(context).caption,
                ),
                const SizedBox(height: AppSpacing.xs),
                // Read as "80 metres": the symbol below is not spoken.
                Text(
                  amountText,
                  semanticsLabel: spokenAmount(
                    l10n,
                    unit,
                    amountValue,
                    amountText,
                  ),
                  style: AppTypography.of(context).display,
                  overflow: .ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                ExcludeSemantics(
                  child: Text(
                    unit.symbol,
                    style: AppTypography.of(context).label,
                  ),
                ),
              ],
            ),
          ),
          if (showEditRate)
            AppIconButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.converterEditRateTooltip(unit.symbol),
              onPressed: () => showEditCurrencyRateDialog(
                context,
                currencyId: unitId,
                currencySymbol: unit.symbol,
                currentRate: state.currencyRates[unitId] ?? 1,
                onSave: notifier.setCurrencyRate,
              ),
            ),
        ],
      ),
    );
  }
}

String _formatAmount(LocalizedNumberFormat format, NumberEntryBuffer amount) {
  if (amount.isEmpty) return '0';
  final negative = amount.isNegative;
  final unsigned = negative ? amount.text.substring(1) : amount.text;
  final formatted = format.formatTyped(unsigned);
  return negative ? '${LocalizedNumberFormat.minusSign}$formatted' : formatted;
}

String _formatResult(LocalizedNumberFormat format, double? result) {
  if (result == null) return '0';
  return format.formatCanonical(_canonicalize(result));
}

/// A plain (never scientific-notation) decimal string for [value], the
/// shape [LocalizedNumberFormat.formatCanonical] expects — good enough for
/// every value this feature's conversions can realistically produce.
String _canonicalize(double value) {
  if (value == 0) return '0';
  var text = value.toStringAsFixed(10);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.endsWith('.') ? text.substring(0, text.length - 1) : text;
  }
  return text;
}

/// Opens a dialog to edit [currencyId]'s "per 1 USD" rate, calling [onSave]
/// with the new rate if confirmed with a valid, positive number.
Future<void> showEditCurrencyRateDialog(
  BuildContext context, {
  required String currencyId,
  required String currencySymbol,
  required double currentRate,
  required Future<void> Function(String currencyId, double rate) onSave,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => _EditCurrencyRateDialog(
    currencyId: currencyId,
    currencySymbol: currencySymbol,
    currentRate: currentRate,
    onSave: onSave,
  ),
);

class _EditCurrencyRateDialog extends StatefulWidget {
  const _EditCurrencyRateDialog({
    required this.currencyId,
    required this.currencySymbol,
    required this.currentRate,
    required this.onSave,
  });

  final String currencyId;
  final String currencySymbol;
  final double currentRate;
  final Future<void> Function(String currencyId, double rate) onSave;

  @override
  State<_EditCurrencyRateDialog> createState() =>
      _EditCurrencyRateDialogState();
}

class _EditCurrencyRateDialogState extends State<_EditCurrencyRateDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: _trimmedRate(widget.currentRate),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.converterEditRateTitle(widget.currencySymbol)),
      content: AppTextField(
        label: l10n.converterEditRateLabel,
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      ),
      actions: [
        AppButton(
          label: MaterialLocalizations.of(context).cancelButtonLabel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: l10n.converterEditRateSaveAction,
          onPressed: () {
            final rate = double.tryParse(_controller.text);
            if (rate != null && rate > 0) {
              widget.onSave(widget.currencyId, rate);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

String _trimmedRate(double rate) {
  var text = rate.toStringAsFixed(6);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  return text.endsWith('.') ? text.substring(0, text.length - 1) : text;
}
