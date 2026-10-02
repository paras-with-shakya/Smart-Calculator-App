import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_sizing.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';

/// How prominent an [AppButton] is.
enum AppButtonVariant {
  /// The main action of a screen or dialog: solid accent.
  primary,

  /// A supporting action: quiet neutral fill.
  secondary,

  /// A low-emphasis action, such as Cancel: text only.
  text,

  /// An action that deletes or cannot be undone: solid error colour.
  destructive,
}

/// The app's button. Every text button in the app is an [AppButton].
///
/// One widget with variants (instead of separate primary and secondary
/// button classes), so size, shape, spacing and loading behaviour are
/// defined once. Shapes and colours come from the theme.
class AppButton extends StatelessWidget {
  /// Creates a button showing [label].
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
  });

  /// The button's text, also its accessibility label.
  final String label;

  /// Called on tap. Null disables the button.
  final VoidCallback? onPressed;

  /// How prominent the button is.
  final AppButtonVariant variant;

  /// Optional icon before the label.
  final IconData? icon;

  /// Optional icon after the label, such as a dropdown arrow.
  final IconData? trailingIcon;

  /// Shows a progress indicator and disables the button. The label stays
  /// in place (invisible), so the button keeps its size and screen readers
  /// still announce it.
  final bool isLoading;

  /// Whether the button fills the available width.
  final bool expand;

  static const double _progressSize = 20;
  static const double _progressStrokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    final onPressed = isLoading ? null : this.onPressed;
    final content = Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: isLoading ? 0 : 1,
          alwaysIncludeSemantics: true,
          child: Row(
            mainAxisSize: .min,
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: .center,
                  overflow: .ellipsis,
                  maxLines: 2,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(trailingIcon),
              ],
            ],
          ),
        ),
        if (isLoading)
          const SizedBox.square(
            dimension: _progressSize,
            child: CircularProgressIndicator(strokeWidth: _progressStrokeWidth),
          ),
      ],
    );

    // "Larger controls" in Settings: a taller minimum (null: the theme's).
    final size = AppSizing.of(context) == 1
        ? null
        : ButtonStyle(
            minimumSize: WidgetStatePropertyAll(
              Size.square(AppSizing.minTarget(context)),
            ),
          );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        style: size,
        child: content,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: onPressed,
        style: size,
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: onPressed,
        style: size,
        child: content,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.of(context).error,
          foregroundColor: AppColors.of(context).onError,
        ).merge(size),
        child: content,
      ),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
