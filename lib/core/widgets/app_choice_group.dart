import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_sizing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// One option of an [AppChoiceGroup].
@immutable
class AppChoice<T> {
  /// Creates an option for [value], shown as [label] with an optional [icon].
  const AppChoice({required this.value, required this.label, this.icon});

  /// The value chosen when this option is picked.
  final T value;

  /// The option's name.
  final String label;

  /// Optional icon next to [label].
  final IconData? icon;
}

/// A single choice among a few options, such as the app theme.
///
/// It shows a segmented button when every label fits on one line in its
/// segment. Otherwise (large text sizes, long translations) it shows the
/// options as a vertical radio list, so a label is never broken in the
/// middle of a word.
class AppChoiceGroup<T> extends StatelessWidget {
  /// Creates a choice group showing [options], with [selected] chosen.
  const AppChoiceGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// The options, in display order.
  final List<AppChoice<T>> options;

  /// The value of the chosen option.
  final T selected;

  /// Called with the value of the option the user picks.
  final ValueChanged<T> onChanged;

  /// Width a Material 3 segment needs besides its label at 100% text: 12 dp
  /// and 16 dp of padding, an 18 dp icon, an 8 dp gap and 2 dp of border.
  /// Flutter shrinks the padding and gap at larger text sizes, so this is
  /// an upper bound.
  static const double _segmentChrome = 56;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        _labelsFitSegments(context, constraints.maxWidth)
        ? _segmented(context)
        : _radioList(),
  );

  bool _labelsFitSegments(BuildContext context, double width) {
    final segmentWidth = width / options.length;
    final style = AppTypography.of(context).label;
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    for (final option in options) {
      final painter = TextPainter(
        text: TextSpan(text: option.label, style: style),
        textScaler: textScaler,
        textDirection: textDirection,
        maxLines: 1,
      )..layout();
      final fits = painter.width + _segmentChrome <= segmentWidth;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }

  Widget _segmented(BuildContext context) => SegmentedButton<T>(
    segments: [
      for (final option in options)
        ButtonSegment(
          value: option.value,
          icon: option.icon == null ? null : Icon(option.icon),
          label: Text(option.label, maxLines: 1, softWrap: false),
        ),
    ],
    selected: {selected},
    onSelectionChanged: (selection) => onChanged(selection.single),
    // "Larger controls" in Settings: a taller segment. A segment's height
    // comes from the visual density (4 dp per unit), not a minimum size.
    style: AppSizing.of(context) == 1
        ? null
        : SegmentedButton.styleFrom(
            visualDensity: VisualDensity(
              vertical:
                  (AppSizing.of(context) - 1) * kMinInteractiveDimension / 4,
            ),
          ),
  );

  // The transparent Material gives the list tiles their own ink surface, so
  // the group works on any background (a coloured box, a card, a page).
  Widget _radioList() => Material(
    type: MaterialType.transparency,
    child: RadioGroup<T>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: Column(
        children: [
          for (final option in options)
            RadioListTile<T>(
              value: option.value,
              title: Text(option.label),
              secondary: option.icon == null ? null : Icon(option.icon),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    ),
  );
}
