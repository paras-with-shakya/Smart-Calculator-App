import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// Shown when there is nothing to display yet, such as an empty history.
class EmptyState extends StatelessWidget {
  /// Creates an empty state with [icon] and [message].
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.action,
  });

  /// Icon of what is empty.
  final IconData icon;

  /// Explains why it is empty, or what fills it.
  final String message;

  /// Optional heading above [message].
  final String? title;

  /// Optional way forward, usually an `AppButton`.
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StatusLayout(
    visual: _IconBadge(icon: icon, color: AppColors.of(context).textMuted),
    title: title,
    message: message,
    action: action,
  );
}

/// Shown when something failed: a human-readable message and, if possible,
/// a way to retry. Never shows raw error details.
class ErrorState extends StatelessWidget {
  /// Creates an error state with [message].
  const ErrorState({super.key, required this.message, this.title, this.action});

  /// What went wrong, in plain words.
  final String message;

  /// Optional heading above [message].
  final String? title;

  /// Optional recovery, usually an `AppButton` that retries.
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StatusLayout(
    visual: _IconBadge(
      icon: Icons.error_outline,
      color: AppColors.of(context).error,
    ),
    title: title,
    message: message,
    action: action,
  );
}

/// Shown while content loads. Screen readers announce [message] when it
/// appears.
class LoadingState extends StatelessWidget {
  /// Creates a loading state with an optional [message].
  const LoadingState({super.key, this.message});

  /// What is loading, in a few words.
  final String? message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: _StatusLayout(
      visual: const CircularProgressIndicator(),
      message: message,
    ),
  );
}

/// The shared layout of the status views: a visual, then an optional title,
/// message and action, centred and scrollable at large text sizes.
class _StatusLayout extends StatelessWidget {
  const _StatusLayout({
    required this.visual,
    this.title,
    this.message,
    this.action,
  });

  final Widget visual;
  final String? title;
  final String? message;
  final Widget? action;

  static const double _maxContentWidth = 360;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Column(
            mainAxisSize: .min,
            children: [
              visual,
              if (title != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  title!,
                  textAlign: .center,
                  style: typography.title.copyWith(color: colors.textPrimary),
                ),
              ],
              if (message != null) ...[
                SizedBox(height: title != null ? AppSpacing.xs : AppSpacing.md),
                Text(
                  message!,
                  textAlign: .center,
                  style: typography.body.copyWith(color: colors.textMuted),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An icon on a quiet circular badge.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static const double _badgeSize = 72;
  static const double _iconSize = 32;

  @override
  Widget build(BuildContext context) => Container(
    width: _badgeSize,
    height: _badgeSize,
    decoration: BoxDecoration(
      color: AppColors.of(context).surfaceMuted,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: _iconSize, color: color),
  );
}
