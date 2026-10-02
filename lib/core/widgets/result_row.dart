import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/widgets/app_card.dart';

/// Shown in place of a result card while a form's inputs are incomplete or
/// invalid — a plain muted line, not `EmptyState` (which is sized for a
/// whole empty screen, not a compact "nothing yet" line inside a card).
class ResultPlaceholder extends StatelessWidget {
  /// Creates a placeholder card saying [message].
  const ResultPlaceholder({
    super.key,
    required this.message,
    this.liveRegion = false,
  });

  /// What to tell the user, such as "Enter values to see the result".
  final String message;

  /// Whether a screen reader announces the placeholder when it appears in
  /// place of a live [ResultCard] (an error, for example).
  final bool liveRegion;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      liveRegion: liveRegion,
      child: AppCard(
        child: Text(
          message,
          style: AppTypography.of(context).body
              .copyWith(color: AppColors.of(context).textMuted),
        ),
      ),
    ),
  );
}

/// A card of [ResultRow]s (and anything else that only shows the result)
/// that a screen reader reads as one item: every label and value in one
/// node, rather than one stop per text.
///
/// With [liveRegion], that node also announces itself whenever its content
/// changes. Android announces a live region only when the live node's own
/// label changes, which is why the card is one merged node. Leave it off for
/// a result that changes with every keystroke (a financial form, the
/// converter); the calculator's live preview is not announced for the same
/// reason (DEC-043).
class ResultCard extends StatelessWidget {
  /// Creates a card of [children], stacked and stretched to its width.
  const ResultCard({
    super.key,
    required this.children,
    this.liveRegion = false,
  });

  /// The result lines.
  final List<Widget> children;

  /// Whether a screen reader announces the card when its content changes.
  final bool liveRegion;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      liveRegion: liveRegion,
      child: AppCard(
        child: Column(crossAxisAlignment: .stretch, children: children),
      ),
    ),
  );
}

/// One label/value line inside a result card: the label on the left and the
/// value on the right when both fit on one line, otherwise the value under
/// the label, so neither is ever cut short (large text, long labels).
class ResultRow extends StatelessWidget {
  /// Creates a row showing [value] next to [label].
  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.wrapValue = false,
  });

  /// What the value is.
  final String label;

  /// The already-formatted value text.
  final String value;

  /// Whether this is the headline figure (larger, e.g. the EMI itself),
  /// rather than a supporting figure (e.g. total interest).
  final bool emphasized;

  /// Whether a [value] too long for the whole width wraps onto more lines
  /// instead of being cut off with an ellipsis. For values that are prose
  /// rather than a number, such as a date or a "2 years, 3 months" span.
  final bool wrapValue;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: OverflowBar(
        spacing: AppSpacing.sm,
        alignment: .spaceBetween,
        overflowAlignment: .start,
        children: [
          Text(label, style: typography.body.copyWith(color: colors.textMuted)),
          Text(
            value,
            maxLines: wrapValue ? null : 1,
            overflow: wrapValue ? null : .ellipsis,
            style: (emphasized ? typography.title : typography.body).copyWith(
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
