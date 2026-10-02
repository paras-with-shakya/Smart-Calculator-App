import 'dart:math' as math;

import 'package:calc_engine/calc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_sizing.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/widgets/calculator_button.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_display.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_keypad.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_memory_keys.dart';
import 'package:smart_calculator/features/calculator/presentation/scientific_function_tray.dart';
import 'package:smart_calculator/features/settings/application/angle_mode_notifier.dart';
import 'package:smart_calculator/features/settings/application/key_feedback_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The scientific calculator: Basic's display, memory row and keypad
/// (reused unchanged), plus a DEG/RAD toggle, a 2nd toggle and the
/// scientific function tray (DEC-013: its own layout, the same calculator
/// state).
///
/// - **Portrait:** the same centred, width-capped column `CalculatorView`
///   uses, with the toggle row and the tray added above the memory row.
/// - **Landscape:** `CalculatorView`'s exact two-column shape (display
///   column, keypad column), with the toggle row and tray stacked into the
///   display column, in the same order as portrait.
///
/// The keypad's square-key sizing keeps a smaller share of the height than
/// Basic's, to leave room for the two new rows.
class ScientificCalculatorView extends ConsumerStatefulWidget {
  /// Creates the calculator.
  const ScientificCalculatorView({super.key});

  /// The widest the keypad gets, matching `CalculatorView`.
  static const double keypadMaxWidth = 480;

  /// The largest share of the height the portrait keypad takes — smaller
  /// than Basic's, since the toggle row and the tray need room too.
  static const double keypadMaxHeightFraction = 0.5;

  /// The share of the width the landscape keypad takes, matching
  /// `CalculatorView`.
  static const double landscapeKeypadWidthFraction = 0.55;

  /// Windows shorter than this use tighter spacing, matching
  /// `CalculatorView`.
  static const double compactHeight = 480;

  @override
  ConsumerState<ScientificCalculatorView> createState() =>
      _ScientificCalculatorViewState();
}

class _ScientificCalculatorViewState
    extends ConsumerState<ScientificCalculatorView> {
  bool _second = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxHeight < ScientificCalculatorView.compactHeight;
      final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
      final verticalPadding = compact ? AppSpacing.xs : AppSpacing.md;
      final gap = compact ? AppSpacing.xs : AppSpacing.sm;
      final width = math.max(0.0, constraints.maxWidth - 2 * horizontalPadding);
      final height = math.max(0.0, constraints.maxHeight - 2 * verticalPadding);
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: constraints.maxWidth > constraints.maxHeight
            ? _landscape(width, height, gap)
            : _portrait(width, height, gap),
      );
    },
  );

  Widget _portrait(double width, double height, double gap) {
    final keypadWidth = math.min(
      width,
      ScientificCalculatorView.keypadMaxWidth,
    );
    final keypadHeight = math.min(
      _squareKeypadHeight(keypadWidth, gap),
      height * ScientificCalculatorView.keypadMaxHeightFraction,
    );
    return Center(
      child: SizedBox(
        width: keypadWidth,
        child: Column(
          children: [
            const Expanded(child: CalculatorDisplay()),
            SizedBox(height: gap),
            _toggleRow(),
            SizedBox(height: gap),
            ScientificFunctionTray(second: _second),
            SizedBox(height: gap),
            const CalculatorMemoryKeys(),
            SizedBox(height: gap),
            SizedBox(
              height: keypadHeight,
              child: CalculatorKeypad(gap: gap),
            ),
          ],
        ),
      ),
    );
  }

  Widget _landscape(double width, double height, double gap) {
    final keypadWidth = math.min(
      width * ScientificCalculatorView.landscapeKeypadWidthFraction,
      ScientificCalculatorView.keypadMaxWidth,
    );
    return Row(
      crossAxisAlignment: .end,
      children: [
        Expanded(
          child: Column(
            children: [
              const Expanded(child: CalculatorDisplay()),
              SizedBox(height: gap),
              _toggleRow(),
              SizedBox(height: gap),
              ScientificFunctionTray(second: _second),
              SizedBox(height: gap),
              const CalculatorMemoryKeys(),
            ],
          ),
        ),
        SizedBox(width: gap * 2),
        SizedBox(
          width: keypadWidth,
          height: math.min(height, _squareKeypadHeight(keypadWidth, gap)),
          child: CalculatorKeypad(gap: gap),
        ),
      ],
    );
  }

  /// The DEG/RAD toggle and the 2nd toggle, side by side. Each is an
  /// ordinary [CalculatorButton] rather than a segmented choice: both are a
  /// single flip between two states, and a plain button never changes
  /// layout mode the way a choice control can at large text sizes, so it
  /// stays a safe fit for this fixed-height row.
  Widget _toggleRow() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: AppSizing.minTarget(context),
      child: Row(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final angleMode = ref.watch(angleModeProvider);
                final degrees = angleMode == AngleMode.degrees;
                return CalculatorButton(
                  kind: CalculatorButtonKind.function,
                  label: degrees
                      ? l10n.keyAngleModeDegrees
                      : l10n.keyAngleModeRadians,
                  semanticLabel: degrees
                      ? l10n.keyAngleModeDegreesLabel
                      : l10n.keyAngleModeRadiansLabel,
                  onPressed: () {
                    ref.read(keyFeedbackProvider).key();
                    ref.read(angleModeProvider.notifier).toggle();
                  },
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: CalculatorButton(
              kind: CalculatorButtonKind.function,
              label: l10n.keySecond,
              semanticLabel: l10n.keySecondLabel,
              selected: _second,
              onPressed: () {
                ref.read(keyFeedbackProvider).key();
                setState(() => _second = !_second);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The height of a keypad [width] wide whose keys are square, matching
  /// `CalculatorView`.
  static double _squareKeypadHeight(double width, double gap) {
    const columns = CalculatorKeypad.columnCount;
    const rows = CalculatorKeypad.rowCount;
    final key = (width - (columns - 1) * gap) / columns;
    return rows * key + (rows - 1) * gap;
  }
}
