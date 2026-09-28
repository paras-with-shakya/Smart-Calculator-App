import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// Shows a modal bottom sheet titled [title], with the content from
/// [builder].
///
/// The sheet is as tall as its content, up to the screen height, and scrolls
/// beyond that (for example at large text sizes). It returns the value the
/// sheet is popped with.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) =>
      AppBottomSheet(title: title, child: builder(sheetContext)),
);

/// The layout of the app's bottom sheets: a heading above scrollable
/// content. Use it through [showAppBottomSheet].
class AppBottomSheet extends StatelessWidget {
  /// Creates a sheet layout with [title] above [child].
  const AppBottomSheet({super.key, required this.title, required this.child});

  /// The sheet's heading.
  final String title;

  /// The sheet's content.
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Semantics(
            header: true,
            child: Text(title, style: AppTypography.of(context).heading),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: child,
          ),
        ),
      ],
    ),
  );
}
