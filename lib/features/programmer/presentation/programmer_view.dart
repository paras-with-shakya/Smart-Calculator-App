import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/key_grid.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_base_rows.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_keypad.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_status_line.dart';
import 'package:smart_calculator/features/programmer/presentation/programmer_word_controls.dart';

/// The programmer calculator: word controls, a status line, the number in
/// all four bases, and the keypad.
///
/// **Portrait:** one column that scrolls only when it must. The keypad sits
/// at the bottom with fixed-height rows (never squeezed below a touch
/// target); the readout above it has a height that depends only on the word
/// size, so the keys do not move while typing.
/// **Landscape:** the controls and readout on the left, the keypad on the
/// right, scrolling together when the window is too short for six key rows.
class ProgrammerView extends StatelessWidget {
  /// Creates the programmer calculator screen.
  const ProgrammerView({super.key});

  /// The widest the content gets.
  static const double maxContentWidth = 480;

  /// The height of a key row at the default text size.
  static const double baseRowHeight = 48;

  /// How far the key rows grow with the text size. Labels shrink to fit a
  /// key, so rows need not follow the text all the way up.
  static const double maxRowScale = 1.3;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(baseRowHeight);
      final rowHeight = math.min(scale, baseRowHeight * maxRowScale);
      return constraints.maxWidth > constraints.maxHeight
          ? _landscape(constraints, rowHeight)
          : _portrait(rowHeight);
    },
  );

  Widget _portrait(double rowHeight) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        // The padding is inside the sliver: a SliverPadding around a
        // SliverFillRemaining does not count its bottom edge, which would make
        // the page scroll by exactly that much.
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Align(
            alignment: .topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  const ProgrammerWordControls(),
                  const SizedBox(height: AppSpacing.sm),
                  const ProgrammerStatusLine(),
                  const SizedBox(height: AppSpacing.sm),
                  const ProgrammerBaseRows(),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.sm),
                  ProgrammerKeypad(rowHeight: rowHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _landscape(BoxConstraints constraints, double rowHeight) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  ProgrammerWordControls(),
                  SizedBox(height: AppSpacing.sm),
                  ProgrammerStatusLine(),
                  SizedBox(height: AppSpacing.sm),
                  ProgrammerBaseRows(),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
              width: constraints.maxWidth * 0.5,
              height: KeyGrid.heightOf(
                ProgrammerKeypad.rowCount,
                rowHeight,
                AppSpacing.sm,
              ),
              child: ProgrammerKeypad(rowHeight: rowHeight),
            ),
          ],
        ),
      );
}
