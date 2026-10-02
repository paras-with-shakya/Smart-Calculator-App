import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/shell/app_shell.dart';
import 'package:smart_calculator/app/theme/app_motion.dart';
import 'package:smart_calculator/app/theme/app_sizing.dart';
import 'package:smart_calculator/app/theme/app_theme.dart';
import 'package:smart_calculator/app/theme/theme_preference_mode.dart';
import 'package:smart_calculator/app/theme/user_text_scaler.dart';
import 'package:smart_calculator/features/settings/application/app_settings_notifier.dart';
import 'package:smart_calculator/features/settings/application/theme_preference_notifier.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The Smart Calculator [MaterialApp]: themes, localization and the shell.
class SmartCalculatorApp extends ConsumerWidget {
  /// Creates the app. It must sit below the `ProviderScope` set up by
  /// `AppRoot`.
  const SmartCalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highContrast = ref.watch(
      appSettingsProvider.select((s) => s.highContrast),
    );
    final textSize = ref.watch(appSettingsProvider.select((s) => s.textSize));
    final largerControls = ref.watch(
      appSettingsProvider.select((s) => s.largerControls),
    );

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      // No "DEBUG" ribbon in the corner of debug builds (the user's request).
      debugShowCheckedModeBanner: false,
      // With "High contrast" on in Settings, the high-contrast themes are
      // the ordinary ones. The `highContrast*` slots stay as they were, so
      // a device that asks for more contrast still gets them either way.
      theme: highContrast ? AppTheme.highContrastLight : AppTheme.light,
      darkTheme: highContrast ? AppTheme.highContrastDark : AppTheme.dark,
      highContrastTheme: AppTheme.highContrastLight,
      highContrastDarkTheme: AppTheme.highContrastDark,
      themeMode: ref.watch(themePreferenceProvider).themeMode,
      themeAnimationStyle: const AnimationStyle(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
      ),
      // Always the same two wrappers, whatever the settings: wrapping
      // conditionally would rebuild the Navigator and close the page the
      // setting was changed on.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: navigationBarStyle(Theme.of(context).brightness),
          child: AppSizing(
            controlScale: largerControls ? AppSizing.largerControlScale : 1,
            child: MediaQuery(
              data: media.copyWith(
                textScaler: textSize.multiplier == 1
                    ? media.textScaler
                    : UserTextScaler(media.textScaler, textSize.multiplier),
              ),
              child: child!,
            ),
          ),
        );
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppShell(),
    );
  }

  /// The system navigation bar over a screen of [brightness]: no bar colour
  /// or scrim of its own (Android 15 draws apps edge to edge and ignores the
  /// colour anyway), and buttons that contrast with the app's background.
  /// Flutter's default styles always ask for light buttons, which vanish
  /// over the light theme with 3-button navigation. The status bar is left
  /// to each screen's app bar.
  static SystemUiOverlayStyle navigationBarStyle(Brightness brightness) =>
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      );
}
