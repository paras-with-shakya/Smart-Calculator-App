import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// The heading of a group of settings or list items.
///
/// Quiet on purpose (muted label style, not the accent), and marked as a
/// heading for screen readers.
class SectionHeader extends StatelessWidget {
  /// Creates a section heading reading [title].
  const SectionHeader(
    this.title, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.sm,
    ),
  });

  /// The heading text.
  final String title;

  /// Space around the heading.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Semantics(
      header: true,
      // Its own node: without it the heading merges with whatever follows it
      // in a list and screen readers hear one long block.
      container: true,
      child: Text(
        title,
        style: AppTypography.of(context).label
            .copyWith(color: AppColors.of(context).textMuted),
      ),
    ),
  );
}
