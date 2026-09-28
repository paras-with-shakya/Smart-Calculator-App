import 'package:flutter/material.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_motion.dart';
import 'package:smart_calculator/app/theme/app_radius.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';

/// The role of a calculator key, which sets its tone (DEC-011):
/// digits are plain, operators and functions are tinted, and `=` is the only
/// solid key.
enum CalculatorButtonKind {
  /// 0-9 and the decimal point: plain tone.
  digit,

  /// + − × ÷ and similar: tinted, with the symbol in the accent colour.
  operator,

  /// AC, brackets, %, backspace: tinted, with the label in the text colour.
  function,

  /// `=`: solid accent.
  equals,

  /// MC, MR, M+, M−, MS: no fill, a smaller label in the muted text colour,
  /// so the memory row stays quieter than the keypad.
  memory,
}

/// A calculator key: a squircle that fills the space its keypad gives it.
///
/// [semanticLabel] is what screen readers announce ("divide", "square
/// root"), because symbols such as ÷ read badly. The visible [label] or
/// [icon] is excluded from semantics. The key never goes below the 48 dp
/// touch target, and its label shrinks rather than overflows.
class CalculatorButton extends StatefulWidget {
  /// Creates a key showing either [label] or [icon].
  const CalculatorButton({
    super.key,
    required this.kind,
    required this.semanticLabel,
    required this.onPressed,
    this.label,
    this.icon,
    this.onLongPress,
  }) : assert(
         (label == null) != (icon == null),
         'Provide exactly one of label and icon.',
       );

  /// The key's role, which sets its colours.
  final CalculatorButtonKind kind;

  /// What screen readers announce.
  final String semanticLabel;

  /// Called on tap. Null disables the key.
  final VoidCallback? onPressed;

  /// Called on long press, such as backspace clearing everything.
  final VoidCallback? onLongPress;

  /// Visible text, such as "7" or "÷".
  final String? label;

  /// Visible icon, such as backspace.
  final IconData? icon;

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton> {
  bool _pressed = false;

  static const double _pressedScale = 0.94;
  static const double _disabledOpacity = 0.38;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    final keyStyle = switch (widget.kind) {
      CalculatorButtonKind.operator ||
      CalculatorButtonKind.equals => typography.keySymbol,
      CalculatorButtonKind.digit ||
      CalculatorButtonKind.function => typography.key,
      CalculatorButtonKind.memory => typography.button,
    };
    final (background, foreground) = switch (widget.kind) {
      CalculatorButtonKind.digit => (colors.digitKey, colors.onDigitKey),
      CalculatorButtonKind.operator => (
        colors.operatorKey,
        colors.onOperatorKey,
      ),
      CalculatorButtonKind.function => (
        colors.functionKey,
        colors.onFunctionKey,
      ),
      CalculatorButtonKind.equals => (colors.equalsKey, colors.onEqualsKey),
      CalculatorButtonKind.memory => (Colors.transparent, colors.textMuted),
    };
    final enabled = widget.onPressed != null;
    final labelColor = enabled
        ? foreground
        : foreground.withValues(alpha: _disabledOpacity);
    final outlined =
        colors.contrastOutline.a > 0 &&
        widget.kind != CalculatorButtonKind.memory;
    final shape = AppRadius.shape(
      AppRadius.xl,
      side: outlined
          ? BorderSide(color: colors.contrastOutline)
          : BorderSide.none,
    );

    final visual = widget.label != null
        ? Text(
            widget.label!,
            maxLines: 1,
            style: keyStyle.copyWith(color: labelColor),
          )
        : Icon(
            widget.icon,
            color: labelColor,
            size: MediaQuery.textScalerOf(context).scale(keyStyle.fontSize!),
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinInteractiveDimension,
          minHeight: kMinInteractiveDimension,
        ),
        child: AnimatedScale(
          scale: _pressed ? _pressedScale : 1,
          duration: AppMotion.durationOf(context, AppMotion.short),
          curve: AppMotion.standard,
          child: Material(
            color: background,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              onLongPress: widget.onLongPress,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Center(
                  child: ExcludeSemantics(
                    child: FittedBox(fit: BoxFit.scaleDown, child: visual),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
