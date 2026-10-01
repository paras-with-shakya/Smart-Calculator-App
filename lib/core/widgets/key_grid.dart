import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';

/// Rows of equally wide keys with a [gap] between them.
///
/// Every row holds the same number of cells and each cell takes an equal
/// share of the width. With [rowHeight] the rows have that fixed height (the
/// grid is as tall as its rows, so a keypad never squeezes a key below its
/// touch target); without it the rows share whatever height the grid is
/// given.
class KeyGrid extends StatelessWidget {
  /// Creates a grid of [rows].
  const KeyGrid({
    super.key,
    required this.rows,
    this.gap = AppSpacing.sm,
    this.rowHeight,
  });

  /// The keys, row by row.
  final List<List<Widget>> rows;

  /// The space between keys, across and down.
  final double gap;

  /// The height of every row, or null to share the available height.
  final double? rowHeight;

  /// The height of a grid of [rowCount] rows of [rowHeight] with [gap]
  /// between them.
  static double heightOf(int rowCount, double rowHeight, double gap) =>
      rowCount * rowHeight + (rowCount - 1) * gap;

  @override
  Widget build(BuildContext context) {
    Widget buildRow(List<Widget> row) => Row(
      crossAxisAlignment: .stretch,
      children: [
        for (final (column, key) in row.indexed) ...[
          if (column > 0) SizedBox(width: gap),
          Expanded(child: key),
        ],
      ],
    );

    return Column(
      mainAxisSize: rowHeight == null ? .max : .min,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) SizedBox(height: gap),
          if (rowHeight == null)
            Expanded(child: buildRow(row))
          else
            SizedBox(height: rowHeight, child: buildRow(row)),
        ],
      ],
    );
  }
}
