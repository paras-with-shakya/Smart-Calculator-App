import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';
import 'package:smart_calculator/app/theme/app_motion.dart';
import 'package:smart_calculator/app/theme/app_spacing.dart';
import 'package:smart_calculator/app/theme/app_typography.dart';
import 'package:smart_calculator/core/formatting/number_format_provider.dart';
import 'package:smart_calculator/core/widgets/display_text.dart';
import 'package:smart_calculator/features/calculator/application/calculator_notifier.dart';
import 'package:smart_calculator/features/calculator/application/memory_notifier.dart';
import 'package:smart_calculator/features/calculator/presentation/calculator_display_formatter.dart';
import 'package:smart_calculator/features/settings/application/decimal_places_provider.dart';
import 'package:smart_calculator/l10n/app_localizations.dart';

/// The calculator's display, anchored to the bottom:
///
/// - a memory badge, while a value is in memory;
/// - the expression a result came from, above the result;
/// - the main line: the expression being typed (tap to move the cursor),
///   or the result;
/// - below it, the live preview or the error message.
///
/// Every line keeps its height when empty, so the display doesn't jump.
/// A long expression shrinks, then wraps, and the display scrolls.
class CalculatorDisplay extends ConsumerWidget {
  /// Creates the display.
  const CalculatorDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorProvider);
    final memory = ref.watch(memoryProvider);
    final l10n = AppLocalizations.of(context);
    final formatter = CalculatorDisplayFormatter(
      ref.watch(numberFormatProvider),
      l10n,
      decimalPlaces: ref.watch(decimalPlacesProvider),
    );
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    final duration = AppMotion.durationOf(context, AppMotion.medium);

    final evaluated = state.evaluatedExpression;
    DisplayText topLine(double? maxLineHeight) => DisplayText(
      evaluated == null ? '' : formatter.expression(evaluated).text,
      key: ValueKey(evaluated),
      style: typography.expression,
      maxLineHeight: maxLineHeight,
      color: colors.textMuted,
      semanticsLabel: evaluated == null
          ? ''
          : formatter.spokenExpression(evaluated),
    );

    final result = state.result;
    final DisplayText Function(double? maxLineHeight) mainLine;
    if (result != null) {
      final shown = formatter.value(result);
      mainLine = (maxLineHeight) => DisplayText(
        shown,
        key: const ValueKey('result'),
        style: typography.result,
        maxLineHeight: maxLineHeight,
        color: colors.textPrimary,
        semanticsLabel: l10n.displayResultLabel(shown),
        liveRegion: true,
      );
    } else if (state.buffer.isEmpty) {
      mainLine = (maxLineHeight) => DisplayText(
        _placeholder,
        key: const ValueKey('expression'),
        style: typography.result,
        maxLineHeight: maxLineHeight,
        color: colors.textMuted,
      );
    } else {
      final expression = formatter.expression(state.buffer);
      final buffer = state.buffer;
      mainLine = (maxLineHeight) => DisplayText(
        expression.text,
        key: const ValueKey('expression'),
        style: typography.result,
        maxLineHeight: maxLineHeight,
        color: colors.textPrimary,
        caretOffset: buffer.cursor == buffer.units.length
            ? null
            : expression.boundaries[buffer.cursor],
        onTapOffset: (offset) => ref
            .read(calculatorProvider.notifier)
            .setCursor(
              CalculatorDisplayFormatter.cursorForOffset(expression, offset),
            ),
        semanticsLabel: formatter.spokenExpression(buffer),
      );
    }

    final error = state.error;
    final value = state.value;
    final DisplayText Function(double? maxLineHeight) bottomLine;
    if (error != null) {
      bottomLine = (maxLineHeight) => DisplayText(
        formatter.error(error),
        style: typography.expression,
        maxLineHeight: maxLineHeight,
        color: colors.error,
        liveRegion: true,
      );
    } else if (state.showsPreview && value != null) {
      final shown = formatter.value(value);
      bottomLine = (maxLineHeight) => DisplayText(
        shown,
        style: typography.expression,
        maxLineHeight: maxLineHeight,
        color: colors.textMuted,
        semanticsLabel: l10n.displayPreviewLabel(shown),
      );
    } else {
      bottomLine = (maxLineHeight) => DisplayText(
        '',
        style: typography.expression,
        maxLineHeight: maxLineHeight,
        color: colors.textMuted,
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _MemoryBadge(value: memory == null ? null : formatter.value(memory)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final lines = constraints.maxHeight - 2 * AppSpacing.xs;
              return SingleChildScrollView(
                reverse: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: .end,
                    crossAxisAlignment: .stretch,
                    children: [
                      _Switcher(
                        duration: duration,
                        child: topLine(lines * _sideLineShare),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _Switcher(
                        duration: duration,
                        child: mainLine(lines * _mainLineShare),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      bottomLine(lines * _sideLineShare),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// How much of the display's height each line may take, so all three fit
  /// even at a large text size in a short display (Scientific's, at 200%):
  /// the main line half, the expression above and the preview below a
  /// quarter each, as their styles' sizes are (48 and 24). At ordinary
  /// sizes the lines are smaller than this and nothing changes.
  static const double _mainLineShare = 0.5;
  static const double _sideLineShare = 0.25;

  /// What the main line shows, muted, before anything is typed.
  static const String _placeholder = '0';
}

/// Cross-fades a display line when what it shows changes kind, such as
/// the expression giving way to its result.
class _Switcher extends StatelessWidget {
  const _Switcher({required this.duration, required this.child});

  final Duration duration;
  final Widget child;

  /// How far a new line rises into place, as a fraction of its height.
  static const double _rise = 0.25;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: duration,
    switchInCurve: AppMotion.standard,
    switchOutCurve: AppMotion.standard,
    layoutBuilder: (current, previous) => Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [...previous, ?current],
    ),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, _rise),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: child,
  );
}

/// "M" and the value in memory; it keeps its space while memory is empty.
class _MemoryBadge extends StatelessWidget {
  const _MemoryBadge({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final typography = AppTypography.of(context);
    final value = this.value;
    return AnimatedOpacity(
      opacity: value == null ? 0 : 1,
      duration: AppMotion.durationOf(context, AppMotion.medium),
      curve: AppMotion.standard,
      child: ExcludeSemantics(
        excluding: value == null,
        child: Semantics(
          container: true,
          label: value == null ? null : l10n.memoryIndicatorLabel(value),
          excludeSemantics: true,
          child: Row(
            children: [
              Text(
                l10n.memoryIndicator,
                style: typography.label.copyWith(color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value ?? '',
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: typography.caption.copyWith(color: colors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
