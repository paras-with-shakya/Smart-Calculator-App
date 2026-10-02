import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// A setting that is on or off: a title, an optional hint under it, and a
/// switch. The whole row is the touch target, and screen readers hear the
/// title, the hint and whether it is on, as one control.
class AppSwitchTile extends StatelessWidget {
  /// Creates a switch row titled [title].
  const AppSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  /// What the switch controls.
  final String title;

  /// A line under [title] saying what the switch does, or null.
  final String? hint;

  /// Whether the switch is on.
  final bool value;

  /// Called with the new value when the row is tapped. Null disables it.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final colors = AppColors.of(context);
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      title: Text(
        title,
        style: typography.body.copyWith(color: colors.textPrimary),
      ),
      subtitle: hint == null
          ? null
          : Text(
              hint!,
              style: typography.caption.copyWith(color: colors.textMuted),
            ),
    );
  }
}
