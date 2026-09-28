import 'package:flutter/material.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';

/// The app's dialog: a title, a message and a row of [AppButton]s.
class AppDialog extends StatelessWidget {
  /// Creates a dialog.
  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
  });

  /// The dialog's heading.
  final String title;

  /// What the user needs to know or decide.
  final String message;

  /// The buttons, least important first. The last one is the main action.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) =>
      AlertDialog(title: Text(title), content: Text(message), actions: actions);
}

/// Asks the user to confirm an action and returns whether they did.
///
/// Dismissing the dialog counts as cancelling. Set [isDestructive] for
/// actions that delete data or cannot be undone: the confirm button then
/// uses the error colour. [cancelLabel] defaults to the platform's
/// translated "Cancel".
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      message: message,
      actions: [
        AppButton(
          label:
              cancelLabel ??
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: isDestructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
