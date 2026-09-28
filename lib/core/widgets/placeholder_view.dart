import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';

/// A centred icon and message shown where a feature has not been built yet.
///
/// Temporary: each use is replaced when its feature is implemented.
class PlaceholderView extends StatelessWidget {
  /// Creates a placeholder showing [icon] above [message].
  const PlaceholderView({super.key, required this.icon, required this.message});

  /// Icon of the feature this placeholder stands in for.
  final IconData icon;

  /// Explains that the feature is not available yet.
  final String message;

  static const double _iconSize = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(icon, size: _iconSize, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: .center,
            ),
          ],
        ),
      ),
    );
  }
}
