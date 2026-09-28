import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_radius.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';

/// A rounded surface that groups related content, optionally tappable.
///
/// When [selected], it takes the accent tint and its text and icons switch
/// to the matching foreground colour. Screen readers announce the selection.
class AppCard extends StatelessWidget {
  /// Creates a card around [child].
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  /// The card's content.
  final Widget child;

  /// Called on tap. Null makes the card static.
  final VoidCallback? onTap;

  /// Whether the card is the selected choice in a group.
  final bool selected;

  /// Space between the card's edge and [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final foreground = selected
        ? colors.onPrimaryContainer
        : colors.textPrimary;
    final shape = AppRadius.shape(
      AppRadius.lg,
      side: colors.contrastOutline.a > 0
          ? BorderSide(color: colors.contrastOutline)
          : BorderSide.none,
    );

    return Semantics(
      button: onTap != null,
      selected: selected ? true : null,
      child: Material(
        color: selected ? colors.primaryContainer : colors.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: IconTheme.merge(
              data: IconThemeData(color: foreground),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foreground),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
