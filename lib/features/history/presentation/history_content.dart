import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/localized_number_format.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/core/widgets/app_icon_button.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/core/widgets/status_views.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
import 'package:smart_calculator/features/history/domain/history_entry.dart';
import 'package:smart_calculator/features/saved_calculations/application/saved_calculations_notifier.dart';
import 'package:smart_calculator/features/saved_calculations/domain/saved_calculation.dart';
import 'package:smart_calculator/features/saved_calculations/presentation/save_name_sheet.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

enum _Tab { history, saved }

/// History and saved calculations, behind a tab toggle: search, a list, and
/// a clear-all action. Shared by the history page and the history panel.
///
/// **History:** tapping an entry reuses its exact result (like MR); copy,
/// save (keep it under a name) and delete actions sit beside it.
///
/// **Saved:** a calculation the user chose to keep. Tapping it reuses its
/// result the same way; rename and delete actions sit beside it.
///
/// Clearing everything, on either tab, asks for confirmation first.
class HistoryContent extends StatefulWidget {
  /// Creates the history content.
  const HistoryContent({super.key});

  @override
  State<HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends State<HistoryContent> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _Tab _tab = _Tab.history;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTab(_Tab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _query = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: AppChoiceGroup<_Tab>(
            options: [
              AppChoice(value: _Tab.history, label: l10n.historyTabLabel),
              AppChoice(value: _Tab.saved, label: l10n.savedTabLabel),
            ],
            selected: _tab,
            onChanged: _selectTab,
          ),
        ),
        Expanded(
          child: switch (_tab) {
            _Tab.history => _HistorySection(
              searchController: _searchController,
              query: _query,
              onQueryChanged: (query) => setState(() => _query = query),
            ),
            _Tab.saved => _SavedSection(
              searchController: _searchController,
              query: _query,
              onQueryChanged: (query) => setState(() => _query = query),
            ),
          },
        ),
      ],
    );
  }
}

/// The search field and clear-all action shared by both tabs' sections.
class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.searchController,
    required this.searchLabel,
    required this.onQueryChanged,
    required this.clearAllTooltip,
    required this.onClearAll,
  });

  final TextEditingController searchController;
  final String searchLabel;
  final ValueChanged<String> onQueryChanged;
  final String clearAllTooltip;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      crossAxisAlignment: .center,
      children: [
        Expanded(
          child: AppTextField(
            label: searchLabel,
            controller: searchController,
            onChanged: onQueryChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButton(
          icon: Icons.delete_sweep_outlined,
          tooltip: clearAllTooltip,
          onPressed: onClearAll,
        ),
      ],
    ),
  );
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection({
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
  });

  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _SearchRow(
              searchController: searchController,
              searchLabel: l10n.historySearchLabel,
              onQueryChanged: onQueryChanged,
              clearAllTooltip: l10n.historyClearAllTooltip,
              onClearAll: entries.isEmpty
                  ? null
                  : () => _confirmClearAll(context, ref, l10n),
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
    final needle = query.trim().toLowerCase();
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
    WidgetRef ref,
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

/// One history entry: its expression, its result, and copy/save/delete
/// actions. Tapping it inserts the exact result into the calculator, the
/// same way MR inserts the memory.
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
      onTap: () => _reuse(context, ref),
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
            icon: Icons.bookmark_add_outlined,
            tooltip: l10n.savedSaveTooltip,
            onPressed: () => _save(context, ref, l10n, resultText),
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

  void _reuse(BuildContext context, WidgetRef ref) {
    ref.read(calculatorProvider.notifier).useHistoryResult(entry.result);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String resultText,
  ) async {
    final name = await promptForName(
      context,
      title: l10n.savedSaveSheetTitle,
      actionLabel: l10n.savedSaveAction,
    );
    if (name == null) return;
    await ref
        .read(savedCalculationsProvider.notifier)
        .add(name: name, expression: entry.expression, result: entry.result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.savedSavedMessage(name))));
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

class _SavedSection extends ConsumerWidget {
  const _SavedSection({
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
  });

  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncEntries = ref.watch(savedCalculationsProvider);
    final format = ref.watch(numberFormatProvider);

    return asyncEntries.when(
      loading: () => LoadingState(message: l10n.savedTabLabel),
      error: (error, stackTrace) => ErrorState(message: '$error'),
      data: (entries) {
        final filtered = _filtered(entries, format);
        return Column(
          children: [
            _SearchRow(
              searchController: searchController,
              searchLabel: l10n.savedSearchLabel,
              onQueryChanged: onQueryChanged,
              clearAllTooltip: l10n.savedClearAllTooltip,
              onClearAll: entries.isEmpty
                  ? null
                  : () => _confirmClearAll(context, ref, l10n),
            ),
            Expanded(
              child: entries.isEmpty
                  ? EmptyState(
                      icon: Icons.bookmark_border,
                      title: l10n.savedEmptyTitle,
                      message: l10n.savedEmptyMessage,
                    )
                  : filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      message: l10n.savedSearchEmptyMessage,
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
                          _SavedTile(entry: filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<SavedCalculation> _filtered(
    List<SavedCalculation> entries,
    LocalizedNumberFormat format,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return entries;
    return [
      for (final entry in entries)
        if (entry.name.toLowerCase().contains(needle) ||
            entry.expression.toLowerCase().contains(needle) ||
            format
                .formatCanonical(entry.result.toDecimalString())
                .toLowerCase()
                .contains(needle))
          entry,
    ];
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.savedClearAllConfirmTitle,
      message: l10n.savedClearAllConfirmMessage,
      confirmLabel: l10n.savedClearAllConfirmAction,
      isDestructive: true,
    );
    if (confirmed) await ref.read(savedCalculationsProvider.notifier).clear();
  }
}

/// One saved calculation: its name, its expression and result, and
/// rename/delete actions. Tapping it inserts the exact result into the
/// calculator, the same way a history entry does.
class _SavedTile extends ConsumerWidget {
  const _SavedTile({required this.entry});

  final SavedCalculation entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    final format = ref.watch(numberFormatProvider);
    final resultText = format.formatCanonical(entry.result.toDecimalString());

    return AppCard(
      onTap: () => _reuse(context, ref),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          Expanded(
            child: Semantics(
              label: l10n.savedEntrySemanticLabel(
                entry.name,
                entry.expression,
                resultText,
              ),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.caption.copyWith(color: colors.primary),
                  ),
                  Text(
                    resultText,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.title.copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    entry.expression,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.caption.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.edit_outlined,
            tooltip: l10n.savedRenameTooltip,
            onPressed: () => _rename(context, ref, l10n),
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            tooltip: l10n.savedDeleteTooltip,
            onPressed: () =>
                ref.read(savedCalculationsProvider.notifier).delete(entry.id),
          ),
        ],
      ),
    );
  }

  void _reuse(BuildContext context, WidgetRef ref) {
    ref.read(calculatorProvider.notifier).useHistoryResult(entry.result);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final name = await promptForName(
      context,
      title: l10n.savedRenameSheetTitle,
      actionLabel: l10n.savedRenameAction,
      initialValue: entry.name,
    );
    if (name == null || name == entry.name) return;
    await ref.read(savedCalculationsProvider.notifier).rename(entry.id, name);
  }
}
