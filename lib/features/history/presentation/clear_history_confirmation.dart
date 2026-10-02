import 'package:flutter/widgets.dart';
import 'package:smart_calculator/core/widgets/app_dialog.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Asks whether to delete the whole history, and returns whether the user
/// confirmed. One place for the wording, shared by the History screen and
/// Settings.
Future<bool> confirmClearHistory(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showConfirmationDialog(
    context,
    title: l10n.historyClearAllConfirmTitle,
    message: l10n.historyClearAllConfirmMessage,
    confirmLabel: l10n.historyClearAllConfirmAction,
    isDestructive: true,
  );
}
