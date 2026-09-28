import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';

/// The app's top bar: a title, the back button when there is somewhere to go
/// back to, and trailing actions (usually `AppIconButton`s).
///
/// It is flat and has the page's background colour; its colours and title
/// style come from the theme.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a top bar showing [title].
  const AppHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.primary = true,
    this.automaticallyImplyLeading = true,
  });

  /// The title, usually a `Text`.
  final Widget title;

  /// Buttons at the end of the bar.
  final List<Widget> actions;

  /// Whether the bar sits at the top of the screen, and so is padded below
  /// the status bar. False for a header inside a panel.
  final bool primary;

  /// Whether to show a back button when the page can be popped.
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    primary: primary,
    automaticallyImplyLeading: automaticallyImplyLeading,
    actions: [
      ...actions,
      const SizedBox(width: AppSpacing.xs),
    ],
  );
}
