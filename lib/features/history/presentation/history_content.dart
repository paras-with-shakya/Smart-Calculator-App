import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/status_views.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
import 'package:smart_calculator/features/history/domain/history_entry.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The calculation history: search, the list of entries and a clear-all
/// action. Shared by the history page and the history panel.
///
/// Tapping an entry reuses its exact result (like MR); a copy and a delete
/// action sit beside it. Clearing everything asks for confirmation first.
class HistoryContent extends ConsumerStatefulWidget {
  /// Creates the history content.
  const HistoryContent({super.key});

  @override
  ConsumerState<HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends ConsumerState<HistoryContent> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncEntries = ref.watch(historyProvider);
    final format = ref.watch(numberFormatProvider);

    return asyncEntries.when(
      loading: () => LoadingState(message: l10n.historyTitle),
      error: (error, stackTrace) => ErrorState(message: '$error'),
      data: (entries) {
        final filtered = _filtered(entries, format);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: .center,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: l10n.historySearchLabel,
                      controller: _searchController,
                      onChanged: (query) => setState(() => _query = query),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppIconButton(
                    icon: Icons.delete_sweep_outlined,
                    tooltip: l10n.historyClearAllTooltip,
                    onPressed: entries.isEmpty
                        ? null
                        : () => _confirmClearAll(context, l10n),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? EmptyState(
                      icon: Icons.history,
                      title: l10n.historyEmptyTitle,
                      message: l10n.historyEmptyMessage,
                    )
                  : filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      message: l10n.historySearchEmptyMessage,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _HistoryTile(entry: filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<HistoryEntry> _filtered(
    List<HistoryEntry> entries,
    LocalizedNumberFormat format,
  ) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return entries;
    return [
      for (final entry in entries)
        if (entry.expression.toLowerCase().contains(needle) ||
            format
                .formatCanonical(entry.result.toDecimalString())
                .toLowerCase()
                .contains(needle))
          entry,
    ];
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.historyClearAllConfirmTitle,
      message: l10n.historyClearAllConfirmMessage,
      confirmLabel: l10n.historyClearAllConfirmAction,
      isDestructive: true,
    );
    if (confirmed) await ref.read(historyProvider.notifier).clear();
  }
}

/// One history entry: its expression, its result, and copy/delete actions.
/// Tapping it inserts the exact result into the calculator, the same way
/// MR inserts the memory.
class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    final format = ref.watch(numberFormatProvider);
    final resultText = format.formatCanonical(entry.result.toDecimalString());

    return AppCard(
      onTap: () {
        ref.read(calculatorProvider.notifier).useHistoryResult(entry.result);
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
      },
      child: Row(
        crossAxisAlignment: .center,
        children: [
          Expanded(
            child: Semantics(
              label: l10n.historyEntrySemanticLabel(
                entry.expression,
                resultText,
              ),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    entry.expression,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.caption.copyWith(color: colors.textMuted),
                  ),
                  Text(
                    resultText,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.title.copyWith(color: colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.copy_outlined,
            tooltip: l10n.historyCopyTooltip,
            onPressed: () => _copy(context, resultText, l10n),
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            tooltip: l10n.historyDeleteTooltip,
            onPressed: () =>
                ref.read(historyProvider.notifier).delete(entry.id),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(
    BuildContext context,
    String resultText,
    AppLocalizations l10n,
  ) async {
    await Clipboard.setData(ClipboardData(text: resultText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.historyCopiedMessage(resultText))),
    );
  }
}
