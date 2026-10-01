import 'package:flutter/material.dart';
import 'package:smart_calculator/core/widgets/app_text_field.dart';

/// A labelled field that shows a calendar date and opens a date picker
/// when tapped.
///
/// It looks and behaves like [AppTextField] (the value can't be typed over;
/// the picker's own text-entry mode still lets a keyboard user type a date).
/// A [value] is a calendar date: only its year, month and day are used.
class AppDateField extends StatefulWidget {
  /// Creates a field labelled [label] showing [value] as [format]ted text.
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.format,
    required this.onChanged,
    required this.pickerHelpText,
    required this.firstDate,
    required this.lastDate,
  });

  /// What the date is for.
  final String label;

  /// The chosen date.
  final DateTime value;

  /// Turns [value] into the text shown, such as `Sun, 8 Mar 2026`.
  final String Function(DateTime value) format;

  /// Called with the date the user picks (a UTC midnight, like [value]).
  /// Not called if the picker is dismissed.
  final ValueChanged<DateTime> onChanged;

  /// The picker dialog's title.
  final String pickerHelpText;

  /// The earliest date the picker offers.
  final DateTime firstDate;

  /// The latest date the picker offers.
  final DateTime lastDate;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.format(widget.value),
  );

  @override
  void didUpdateWidget(AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.format(widget.value);
    if (_controller.text != text) _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    // The picker works in local time; hand it a local date with the same
    // year, month and day, and keep only those three from what it returns.
    final first = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final last = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    var initial = DateTime(
      widget.value.year,
      widget.value.month,
      widget.value.day,
    );
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: widget.pickerHelpText,
    );
    if (picked == null) return;
    widget.onChanged(DateTime.utc(picked.year, picked.month, picked.day));
  }

  @override
  // A read-only text field exposes no tap action to screen readers (it can be
  // focused but not activated), so the tap is added to the merged node.
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      onTap: _pick,
      child: AppTextField(
        label: widget.label,
        controller: _controller,
        readOnly: true,
        onTap: _pick,
        suffixIcon: const ExcludeSemantics(
          child: Icon(Icons.calendar_today_outlined),
        ),
      ),
    ),
  );
}
