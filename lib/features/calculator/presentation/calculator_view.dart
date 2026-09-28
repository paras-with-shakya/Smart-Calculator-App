import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/domain/calculator_key.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_display.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_keypad.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_memory_keys.dart';

/// The basic calculator: display, memory row and keypad.
///
/// - **Portrait** (taller than wide): a centred column at most
///   [keypadMaxWidth] wide. The keypad's keys are square, unless that would
///   take more than [keypadMaxHeightFraction] of the height.
/// - **Landscape:** the display and memory row on the left, the keypad on
///   the right.
/// - **Short windows** (below [compactHeight], such as phones in
///   landscape) use tighter spacing, so keys keep their 48 dp touch target.
///
/// A hardware keyboard works too: digits and operators (`*`, `x` and `/`
/// included), Enter or `=`, Backspace, Escape or Delete for AC, the arrow,
/// Home and End keys to move the cursor, and Ctrl+V to paste.
class CalculatorView extends ConsumerStatefulWidget {
  /// Creates the calculator.
  const CalculatorView({super.key});

  /// The widest the keypad gets.
  static const double keypadMaxWidth = 480;

  /// The largest share of the height the portrait keypad takes.
  static const double keypadMaxHeightFraction = 0.6;

  /// The share of the width the landscape keypad takes.
  static const double landscapeKeypadWidthFraction = 0.55;

  /// Windows shorter than this use tighter spacing (Material's compact
  /// height class).
  static const double compactHeight = 480;

  @override
  ConsumerState<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends ConsumerState<CalculatorView> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Calculator');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focusNode,
    autofocus: true,
    onKeyEvent: _handleKeyEvent,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < CalculatorView.compactHeight;
        final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
        final verticalPadding = compact ? AppSpacing.xs : AppSpacing.md;
        final gap = compact ? AppSpacing.xs : AppSpacing.sm;
        final width = math.max(
          0.0,
          constraints.maxWidth - 2 * horizontalPadding,
        );
        final height = math.max(
          0.0,
          constraints.maxHeight - 2 * verticalPadding,
        );
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
    ),
  );

  Widget _portrait(double width, double height, double gap) {
    final keypadWidth = math.min(width, CalculatorView.keypadMaxWidth);
    final keypadHeight = math.min(
      _squareKeypadHeight(keypadWidth, gap),
      height * CalculatorView.keypadMaxHeightFraction,
    );
    return Center(
      child: SizedBox(
        width: keypadWidth,
        child: Column(
          children: [
            const Expanded(child: CalculatorDisplay()),
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
      width * CalculatorView.landscapeKeypadWidthFraction,
      CalculatorView.keypadMaxWidth,
    );
    return Row(
      crossAxisAlignment: .end,
      children: [
        Expanded(
          child: Column(
            children: [
              const Expanded(child: CalculatorDisplay()),
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

  /// The height of a keypad [width] wide whose keys are square.
  static double _squareKeypadHeight(double width, double gap) {
    const columns = CalculatorKeypad.columnCount;
    const rows = CalculatorKeypad.rowCount;
    final key = (width - (columns - 1) * gap) / columns;
    return rows * key + (rows - 1) * gap;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final notifier = ref.read(calculatorProvider.notifier);
    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;

    if (keyboard.isControlPressed || keyboard.isMetaPressed) {
      if (key != LogicalKeyboardKey.keyV) return KeyEventResult.ignored;
      unawaited(_paste());
      return KeyEventResult.handled;
    }

    final calculatorKey = switch (key) {
      LogicalKeyboardKey.enter ||
      LogicalKeyboardKey.numpadEnter => CalculatorKey.equals,
      LogicalKeyboardKey.backspace => CalculatorKey.backspace,
      LogicalKeyboardKey.escape ||
      LogicalKeyboardKey.delete => CalculatorKey.allClear,
      _ => null,
    };
    if (calculatorKey != null) {
      notifier.press(calculatorKey);
      return KeyEventResult.handled;
    }

    final buffer = ref.read(calculatorProvider).buffer;
    final cursorMove = switch (key) {
      LogicalKeyboardKey.arrowLeft => buffer.cursor - 1,
      LogicalKeyboardKey.arrowRight => buffer.cursor + 1,
      LogicalKeyboardKey.home => 0,
      LogicalKeyboardKey.end => buffer.units.length,
      _ => null,
    };
    if (cursorMove != null) {
      notifier.setCursor(cursorMove);
      return KeyEventResult.handled;
    }

    // A comma types the decimal point, as the numpad key does on
    // keyboards for regions that write decimals with a comma.
    final character = event.character == ',' ? '.' : event.character;
    if (character != null && notifier.typeText(character)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || !mounted) return;
    ref
        .read(calculatorProvider.notifier)
        .typeText(ref.read(numberFormatProvider).toPlainInput(text));
  }
}
