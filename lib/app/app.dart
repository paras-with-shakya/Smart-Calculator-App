import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/shell/app_shell.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/app/theme/theme_preference_mode.dart';
import 'package:smart_calculator/features/settings/application/theme_preference_notifier.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The Smart Calculator [MaterialApp]: themes, localization and the shell.
class SmartCalculatorApp extends ConsumerWidget {
  /// Creates the app. It must sit below the `ProviderScope` set up by
  /// `AppRoot`.
  const SmartCalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ref.watch(themePreferenceProvider).themeMode,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const AppShell(),
  );
}
