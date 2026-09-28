import 'package:flutter/material.dart';

/// How prominent an [AppIconButton] is.
enum AppIconButtonVariant {
  /// Icon only, such as the header actions.
  standard,

  /// Icon on a quiet neutral fill.
  tonal,
}

/// The app's icon-only button.
///
/// [tooltip] is required: it is shown on long press and hover, and it is the
/// button's accessibility label, so no icon button can be unlabelled.
class AppIconButton extends StatelessWidget {
  /// Creates an icon button labelled [tooltip].
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
  });

  /// The icon shown.
  final IconData icon;

  /// What the button does, in a few words.
  final String tooltip;

  /// Called on tap. Null disables the button.
  final VoidCallback? onPressed;

  /// How prominent the button is.
  final AppIconButtonVariant variant;

  @override
  Widget build(BuildContext context) => switch (variant) {
    AppIconButtonVariant.standard => IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
    AppIconButtonVariant.tonal => IconButton.filledTonal(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  };
}
