import 'dart:math' as math;

import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/modes/calculator_mode.dart';
import 'package:smart_calculator/app/modes/calculator_mode_presentation.dart';
import 'package:smart_calculator/app/modes/mode_grid.dart';
import 'package:smart_calculator/app/navigation/app_navigator.dart';
import 'package:smart_calculator/app/navigation/app_route.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/app_info.dart';
import 'package:smart_calculator/core/layout/layout_limits.dart';
import 'package:smart_calculator/core/widgets/app_bottom_sheet.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';
import 'package:smart_calculator/core/widgets/app_choice_group.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/core/widgets/app_header.dart';
import 'package:smart_calculator/core/widgets/app_switch_tile.dart';
import 'package:smart_calculator/core/widgets/section_header.dart';
import 'package:smart_calculator/core/widgets/setting_row.dart';
import 'package:smart_calculator/features/history/application/history_notifier.dart';
import 'package:smart_calculator/features/history/domain/history_entry.dart';
import 'package:smart_calculator/features/history/presentation/clear_history_confirmation.dart';
import 'package:smart_calculator/features/settings/application/angle_mode_notifier.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';
import 'package:smart_calculator/features/settings/application/theme_preference_notifier.dart';
import 'package:smart_calculator/features/settings/domain/app_settings.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The settings page: appearance, the calculator, the history,
/// accessibility and About.
///
/// Every control saves as soon as it changes. Settings that change what the
/// app looks like (theme, text size, larger controls, high contrast) apply
/// to this page too, straight away.
class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  /// The widest the settings column gets.
  static const double maxContentWidth = LayoutLimits.maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            // Centre a column of at most maxContentWidth, but let the whole
            // width scroll.
            padding: EdgeInsets.symmetric(
              horizontal: math.max(
                0,
                (constraints.maxWidth - maxContentWidth) / 2,
              ),
              vertical: AppSpacing.sm,
            ),
            children: const [
              _AppearanceSection(),
              _CalculatorSection(),
              _HistorySection(),
              _AccessibilitySection(),
              _AboutSection(),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preference = ref.watch(themePreferenceProvider);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(l10n.settingsAppearanceSection),
        SettingRow(
          label: l10n.settingsThemeLabel,
          child: AppChoiceGroup<ThemePreference>(
            options: [
              for (final option in ThemePreference.values)
                AppChoice(
                  value: option,
                  label: option.label(l10n),
                  icon: option.icon,
                ),
            ],
            selected: preference,
            onChanged: (choice) => ref
                .read(themePreferenceProvider.notifier)
                .setPreference(choice),
          ),
        ),
      ],
    );
  }
}

class _CalculatorSection extends ConsumerWidget {
  const _CalculatorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final angleMode = ref.watch(angleModeProvider);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(l10n.settingsCalculatorSection),
        const _DefaultModeSetting(),
        SettingRow(
          label: l10n.settingsAngleModeLabel,
          hint: l10n.settingsAngleModeHint,
          child: AppChoiceGroup<AngleMode>(
            options: [
              AppChoice(
                value: AngleMode.degrees,
                label: l10n.settingsAngleDegrees,
              ),
              AppChoice(
                value: AngleMode.radians,
                label: l10n.settingsAngleRadians,
              ),
            ],
            selected: angleMode,
            onChanged: ref.read(angleModeProvider.notifier).setMode,
          ),
        ),
        _SheetChoiceSetting<DecimalPlaces>(
          label: l10n.settingsDecimalPlacesLabel,
          hint: l10n.settingsDecimalPlacesHint,
          options: [
            for (final option in DecimalPlaces.values)
              AppChoice(value: option, label: _placesLabel(l10n, option)),
          ],
          selected: settings.decimalPlaces,
          onChanged: notifier.setDecimalPlaces,
        ),
        AppSwitchTile(
          title: l10n.settingsHapticsLabel,
          hint: l10n.settingsHapticsHint,
          value: settings.haptics,
          onChanged: (value) => notifier.setHaptics(enabled: value),
        ),
        AppSwitchTile(
          title: l10n.settingsKeySoundLabel,
          hint: l10n.settingsKeySoundHint,
          value: settings.keySound,
          onChanged: (value) => notifier.setKeySound(enabled: value),
        ),
      ],
    );
  }
}

class _DefaultModeSetting extends ConsumerWidget {
  const _DefaultModeSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(appSettingsProvider.select((s) => s.defaultMode));

    Future<void> choose() async {
      final picked = await showAppBottomSheet<CalculatorMode>(
        context: context,
        title: l10n.settingsDefaultModeSheetTitle,
        builder: (sheetContext) => ModeGrid(
          selected: mode,
          onSelected: (picked) => Navigator.of(sheetContext).pop(picked),
        ),
      );
      if (picked != null) {
        await ref.read(appSettingsProvider.notifier).setDefaultMode(picked);
      }
    }

    return SettingRow(
      label: l10n.settingsDefaultModeLabel,
      hint: l10n.settingsDefaultModeHint,
      child: Semantics(
        label: '${l10n.settingsDefaultModeLabel}, ${mode.label(l10n)}',
        button: true,
        onTap: choose,
        excludeSemantics: true,
        child: AppButton(
          label: mode.label(l10n),
          icon: mode.icon,
          variant: AppButtonVariant.secondary,
          trailingIcon: Icons.arrow_drop_down,
          expand: true,
          onPressed: choose,
        ),
      ),
    );
  }
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final isEmpty = ref.watch(
      historyProvider.select((entries) => entries.value?.isEmpty ?? true),
    );

    Future<void> changeLimit(HistoryLimit limit) async {
      final keep = limit.keep;
      if (keep != null) {
        final List<HistoryEntry> entries;
        try {
          entries = await ref.read(historyProvider.future);
        } on Object {
          // History cannot be read just now: keep the choice anyway. Older
          // entries are trimmed the next time a calculation is saved.
          await notifier.setHistoryLimit(limit);
          return;
        }
        if (!context.mounted) return;
        if (entries.length > keep) {
          final confirmed = await showConfirmationDialog(
            context,
            title: l10n.settingsHistoryLimitConfirmTitle,
            message: l10n.settingsHistoryLimitConfirmMessage(
              keep,
              entries.length - keep,
            ),
            confirmLabel: l10n.settingsHistoryLimitConfirmAction,
            isDestructive: true,
          );
          if (!confirmed) return;
          await notifier.setHistoryLimit(limit);
          await ref.read(historyProvider.notifier).trimTo(keep);
          return;
        }
      }
      await notifier.setHistoryLimit(limit);
    }

    Future<void> clearHistory() async {
      if (!await confirmClearHistory(context)) return;
      await ref.read(historyProvider.notifier).clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsHistoryCleared)));
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(l10n.settingsHistorySection),
        AppSwitchTile(
          title: l10n.settingsHistoryEnabledLabel,
          hint: l10n.settingsHistoryEnabledHint,
          value: settings.historyEnabled,
          onChanged: (value) => notifier.setHistoryEnabled(enabled: value),
        ),
        _SheetChoiceSetting<HistoryLimit>(
          label: l10n.settingsHistoryLimitLabel,
          hint: l10n.settingsHistoryLimitHint,
          options: [
            for (final limit in HistoryLimit.values)
              AppChoice(
                value: limit,
                label: limit.keep == null
                    ? l10n.settingsHistoryLimitAll
                    : '${limit.keep}',
              ),
          ],
          selected: settings.historyLimit,
          onChanged: changeLimit,
        ),
        SettingRow(
          label: l10n.settingsClearHistoryLabel,
          hint: l10n.settingsClearHistoryHint,
          child: AppButton(
            label: l10n.settingsClearHistoryLabel,
            variant: AppButtonVariant.destructive,
            expand: true,
            onPressed: isEmpty ? null : clearHistory,
          ),
        ),
      ],
    );
  }
}

class _AccessibilitySection extends ConsumerWidget {
  const _AccessibilitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(l10n.settingsAccessibilitySection),
        SettingRow(
          label: l10n.settingsTextSizeLabel,
          hint: l10n.settingsTextSizeHint,
          child: AppChoiceGroup<TextSize>(
            options: [
              for (final size in TextSize.values)
                AppChoice(
                  value: size,
                  label: '${(size.multiplier * 100).round()}%',
                ),
            ],
            selected: settings.textSize,
            onChanged: notifier.setTextSize,
          ),
        ),
        AppSwitchTile(
          title: l10n.settingsLargerControlsLabel,
          hint: l10n.settingsLargerControlsHint,
          value: settings.largerControls,
          onChanged: (value) => notifier.setLargerControls(enabled: value),
        ),
        AppSwitchTile(
          title: l10n.settingsHighContrastLabel,
          hint: l10n.settingsHighContrastHint,
          value: settings.highContrast,
          onChanged: (value) => notifier.setHighContrast(enabled: value),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typography = AppTypography.of(context);
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(l10n.settingsAboutSection),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Semantics(
            container: true,
            label: l10n.settingsVersionSemantics(AppInfo.displayVersion),
            excludeSemantics: true,
            // A Wrap, not a Row: at a very large text size the version drops
            // under its label instead of overflowing.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.md,
              children: [
                Text(
                  l10n.settingsVersionLabel,
                  style: typography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  AppInfo.displayVersion,
                  style: typography.body.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: AppCard(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.settingsPrivacyTitle,
                    style: typography.title.copyWith(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final paragraph in [
                  l10n.settingsPrivacyInternet,
                  l10n.settingsPrivacyStorage,
                  l10n.settingsPrivacyRemoval,
                ]) ...[
                  Text(
                    paragraph,
                    style: typography.body.copyWith(color: colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Text(
                  l10n.settingsPrivacyNotPolicy,
                  style: typography.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: AppButton(
            label: l10n.settingsLicensesLabel,
            variant: AppButtonVariant.secondary,
            trailingIcon: Icons.chevron_right,
            expand: true,
            onPressed: () => context.pushRoute<void>(const LicensesRoute()),
          ),
        ),
      ],
    );
  }
}

extension on ThemePreference {
  IconData get icon => switch (this) {
    ThemePreference.system => Icons.brightness_auto_outlined,
    ThemePreference.light => Icons.light_mode_outlined,
    ThemePreference.dark => Icons.dark_mode_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ThemePreference.system => l10n.themeSystem,
    ThemePreference.light => l10n.themeLight,
    ThemePreference.dark => l10n.themeDark,
  };
}

/// The label of a decimal-places choice: "Auto" or the number.
String _placesLabel(AppLocalizations l10n, DecimalPlaces places) =>
    places.places == null ? l10n.settingsDecimalPlacesAuto : '${places.places}';

/// A setting with more choices than fit side by side on a phone: the row
/// shows the current one on a button and opens all of them in a sheet.
class _SheetChoiceSetting<T> extends StatelessWidget {
  const _SheetChoiceSetting({
    required this.label,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// What the setting is; also the sheet's title.
  final String label;

  /// A line under [label] saying what the setting does.
  final String hint;

  /// The choices, in order.
  final List<AppChoice<T>> options;

  /// The current choice.
  final T selected;

  /// Called with the choice the user picks (not with the current one).
  final Future<void> Function(T choice) onChanged;

  @override
  Widget build(BuildContext context) {
    final current = options
        .firstWhere((option) => option.value == selected)
        .label;

    Future<void> choose() async {
      // Wrapped so that a choice of `null` could never be mistaken for a
      // dismissed sheet.
      final picked = await showAppBottomSheet<({T value})>(
        context: context,
        title: label,
        builder: (sheetContext) => AppChoiceGroup<T>(
          options: options,
          selected: selected,
          onChanged: (value) => Navigator.of(sheetContext).pop((value: value)),
        ),
      );
      if (picked != null && picked.value != selected) {
        await onChanged(picked.value);
      }
    }

    return SettingRow(
      label: label,
      hint: hint,
      child: Semantics(
        label: '$label, $current',
        button: true,
        onTap: choose,
        excludeSemantics: true,
        child: AppButton(
          label: current,
          variant: AppButtonVariant.secondary,
          trailingIcon: Icons.arrow_drop_down,
          expand: true,
          onPressed: choose,
        ),
      ),
    );
  }
}
