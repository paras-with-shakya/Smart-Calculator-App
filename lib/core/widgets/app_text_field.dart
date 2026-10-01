import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// The app's text input, with a visible label.
///
/// [label] is required: it stays visible above the value and is the
/// field's accessibility label. Shape and colours come from the theme.
class AppTextField extends StatelessWidget {
  /// Creates a text field labelled [label].
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  /// What the field is for.
  final String label;

  /// Controls the field's text.
  final TextEditingController? controller;

  /// Controls the field's focus.
  final FocusNode? focusNode;

  /// Example input, shown while the field is empty.
  final String? hint;

  /// Guidance shown below the field.
  final String? helperText;

  /// A problem with the value, shown below the field in the error colour.
  final String? errorText;

  /// Text before the value, such as a currency symbol.
  final String? prefixText;

  /// Text after the value, such as a unit or "%".
  final String? suffixText;

  /// The on-screen keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action button.
  final TextInputAction? textInputAction;

  /// Restrictions on what can be typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Called on every change.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the value can be selected but not typed over. For a field that
  /// is filled by another control, such as a date picker opened by [onTap].
  final bool readOnly;

  /// Called when the field is tapped.
  final VoidCallback? onTap;

  /// A widget after the value, such as a calendar icon.
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    readOnly: readOnly,
    onTap: onTap,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    style: AppTypography.of(context).body
        .copyWith(color: AppColors.of(context).textPrimary),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      prefixText: prefixText,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
    ),
  );
}
