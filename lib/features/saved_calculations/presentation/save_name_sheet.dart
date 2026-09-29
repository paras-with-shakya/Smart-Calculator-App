import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/app_bottom_sheet.dart';
import 'package:smart_calculator/core/widgets/app_button.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// Asks for a name in a sheet titled [title], starting from [initialValue],
/// with its action button labelled [actionLabel].
///
/// Returns the trimmed name, or null if the user backed out. The action
/// button is disabled while the field is empty.
Future<String?> promptForName(
  BuildContext context, {
  required String title,
  required String actionLabel,
  String initialValue = '',
}) => showAppBottomSheet<String>(
  context: context,
  title: title,
  builder: (context) =>
      _NameSheetContent(actionLabel: actionLabel, initialValue: initialValue),
);

class _NameSheetContent extends StatefulWidget {
  const _NameSheetContent({
    required this.actionLabel,
    required this.initialValue,
  });

  final String actionLabel;
  final String initialValue;

  @override
  State<_NameSheetContent> createState() => _NameSheetContentState();
}

class _NameSheetContentState extends State<_NameSheetContent> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  late String _name = widget.initialValue;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        AppTextField(
          label: l10n.savedNameLabel,
          hint: l10n.savedNameHint,
          controller: _controller,
          textInputAction: .done,
          onChanged: (value) => setState(() => _name = value),
          onSubmitted: (value) => _submit(context, value),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: widget.actionLabel,
          expand: true,
          onPressed: _name.trim().isEmpty
              ? null
              : () => _submit(context, _name),
        ),
      ],
    );
  }

  void _submit(BuildContext context, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    Navigator.of(context).pop(trimmed);
  }
}
