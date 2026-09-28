import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/features/settings/application/theme_preference_notifier.dart';
import 'package:smart_calculator/features/settings/domain/theme_preference.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The settings page.
///
/// Phase 1 foundation: only the theme choice exists. Phase 10 builds the full
/// settings screen.
class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            _SectionHeader(l10n.settingsAppearanceSection),
            const _ThemePreferenceSetting(),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ThemePreferenceSetting extends ConsumerWidget {
  const _ThemePreferenceSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preference = ref.watch(themePreferenceProvider);
    return ListTile(
      title: Text(l10n.settingsThemeLabel),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: SegmentedButton<ThemePreference>(
          segments: [
            for (final option in ThemePreference.values)
              ButtonSegment(
                value: option,
                icon: Icon(option.icon),
                label: Text(option.label(l10n)),
              ),
          ],
          selected: {preference},
          onSelectionChanged: (selection) => ref
              .read(themePreferenceProvider.notifier)
              .setPreference(selection.single),
        ),
      ),
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
