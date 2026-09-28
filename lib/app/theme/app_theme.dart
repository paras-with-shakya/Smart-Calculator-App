import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_radius.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// The app's themes, built from the design tokens.
///
/// Each theme maps `AppColors` and `AppTypography` onto Flutter's
/// [ColorScheme], [TextTheme] and component themes. Material widgets then
/// follow the design system on their own, and our widgets read the tokens
/// through the theme extensions.
abstract final class AppTheme {
  /// Light theme.
  static final ThemeData light = _build(AppColors.light, Brightness.light);

  /// Dark theme.
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  /// Light theme used when the platform asks for more contrast.
  static final ThemeData highContrastLight = _build(
    AppColors.highContrastLight,
    Brightness.light,
  );

  /// Dark theme used when the platform asks for more contrast.
  static final ThemeData highContrastDark = _build(
    AppColors.highContrastDark,
    Brightness.dark,
  );

  /// Minimum size of buttons: the Material 48 dp touch target.
  static const Size _buttonMinimumSize = Size(
    kMinInteractiveDimension,
    kMinInteractiveDimension,
  );

  static ThemeData _build(AppColors colors, Brightness brightness) {
    const typography = AppTypography.standard;
    final outline = colors.contrastOutline.a > 0
        ? BorderSide(color: colors.contrastOutline)
        : BorderSide.none;
    final buttonShape = AppRadius.shape(AppRadius.md, side: outline);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.surfaceMuted,
      onSecondaryContainer: colors.textPrimary,
      error: colors.error,
      onError: colors.onError,
      surface: colors.background,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textMuted,
      surfaceContainerLowest: colors.card,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.surface,
      surfaceContainerHighest: colors.surfaceMuted,
      outline: colors.outline,
      outlineVariant: colors.divider,
      surfaceTint: Colors.transparent,
    );

    final baseTextTheme = ThemeData(
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
    ).textTheme;
    final textTheme = baseTextTheme
        .copyWith(
          titleLarge: baseTextTheme.titleLarge?.merge(typography.heading),
          titleMedium: baseTextTheme.titleMedium?.merge(typography.title),
          bodyLarge: baseTextTheme.bodyLarge?.merge(typography.body),
          bodySmall: baseTextTheme.bodySmall?.merge(typography.caption),
          labelLarge: baseTextTheme.labelLarge?.merge(typography.button),
          labelMedium: baseTextTheme.labelMedium?.merge(typography.label),
        )
        .apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors, typography],
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: typography.heading.copyWith(color: colors.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _buttonMinimumSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: typography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _buttonMinimumSize,
          padding: buttonPadding,
          shape: AppRadius.shape(AppRadius.md),
          side: BorderSide(color: colors.outline),
          textStyle: typography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: _buttonMinimumSize,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: AppRadius.shape(AppRadius.md),
          textStyle: typography.button,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppRadius.shape(AppRadius.lg, side: outline),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: AppRadius.shape(AppRadius.xl, side: outline),
        titleTextStyle: typography.heading.copyWith(color: colors.textPrimary),
        contentTextStyle: typography.body.copyWith(color: colors.textMuted),
      ),
      // Sheets use the page background, so cards inside them stand out the
      // same way they do on a page.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.background,
        modalBackgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colors.outline,
        shape: RoundedSuperellipseBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          side: outline,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: typography.body.copyWith(color: colors.textMuted),
        hintStyle: typography.body.copyWith(color: colors.textMuted),
        helperStyle: typography.caption.copyWith(color: colors.textMuted),
        errorStyle: typography.caption.copyWith(color: colors.error),
        border: _inputBorder(colors.contrastOutline),
        enabledBorder: _inputBorder(colors.contrastOutline),
        focusedBorder: _inputBorder(colors.primary, width: 2),
        errorBorder: _inputBorder(colors.error),
        focusedErrorBorder: _inputBorder(colors.error, width: 2),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.background,
        indicatorColor: colors.primaryContainer,
        indicatorShape: AppRadius.shape(AppRadius.lg),
        selectedIconTheme: IconThemeData(color: colors.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colors.textMuted),
        selectedLabelTextStyle: typography.label.copyWith(
          color: colors.textPrimary,
        ),
        unselectedLabelTextStyle: typography.label.copyWith(
          color: colors.textMuted,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colors.primaryContainer,
          selectedForegroundColor: colors.onPrimaryContainer,
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.outline),
          textStyle: typography.label,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textMuted,
        textColor: colors.textPrimary,
        selectedColor: colors.onPrimaryContainer,
        selectedTileColor: colors.primaryContainer,
        shape: AppRadius.shape(AppRadius.md),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionHandleColor: colors.primary,
      ),
    );
  }

  /// A filled text field's border: rounded on every corner, with the line
  /// along the bottom in [color] (the label floats inside the fill, as in
  /// Material's filled style). A fully transparent colour means no line at
  /// all; a zero-width side would still draw a hairline.
  static UnderlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      UnderlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: color.a == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
}
