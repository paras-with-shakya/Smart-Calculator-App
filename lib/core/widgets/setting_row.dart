import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// A labelled setting whose control sits under its label: the label, an
/// optional hint, then [child] across the full width (a choice group, a
/// button).
///
/// A switch uses `AppSwitchTile` instead, which is its own labelled row.
class SettingRow extends StatelessWidget {
  /// Creates a row labelled [label] around [child].
  const SettingRow({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  /// What the setting is.
  final String label;

  /// A line under [label] saying what the setting does, or null.
  final String? hint;

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            label,
            style: typography.body.copyWith(color: colors.textPrimary),
          ),
          if (hint != null)
            Text(
              hint!,
              style: typography.caption.copyWith(color: colors.textMuted),
            ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
