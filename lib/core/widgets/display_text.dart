import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:smart_calculator/app/theme/app_colors.dart';

/// A line of a calculator display: end-aligned text that shrinks to fit its
/// width, then wraps.
///
/// - The text starts at [style]'s size, with the user's text scale, and
///   shrinks down to [minScale] of that to stay on one line. Beyond that it
///   wraps at the smallest size, so nothing is ever cut off.
/// - With [caretOffset], a caret is drawn before that text offset, in the
///   accent colour.
/// - With [onTapOffset], a tap reports the text offset nearest to it, so an
///   expression can be edited where it was tapped.
///
/// Screen readers hear [semanticsLabel], or [text] when it is null.
class DisplayText extends LeafRenderObjectWidget {
  /// Creates a display line showing [text].
  const DisplayText(
    this.text, {
    super.key,
    required this.style,
    required this.color,
    this.minScale = 0.5,
    this.caretOffset,
    this.onTapOffset,
    this.semanticsLabel,
    this.liveRegion = false,
  }) : assert(minScale > 0 && minScale <= 1, 'minScale must be in (0, 1].');

  /// The text to show.
  final String text;

  /// The largest style the text is shown in, from `AppTypography`.
  final TextStyle style;

  /// The text colour, from `AppColors`.
  final Color color;

  /// How far the text may shrink before it wraps, as a fraction of [style].
  final double minScale;

  /// Where to draw a caret, as an offset into [text]; null for none.
  final int? caretOffset;

  /// Called with the text offset nearest a tap; null makes the text
  /// ignore taps.
  final ValueChanged<int>? onTapOffset;

  /// What screen readers hear instead of [text].
  final String? semanticsLabel;

  /// Whether screen readers announce changes as they happen, as for a
  /// result.
  final bool liveRegion;

  @override
  RenderDisplayText createRenderObject(BuildContext context) =>
      RenderDisplayText(
        text: text,
        style: style,
        color: color,
        minScale: minScale,
        caretOffset: caretOffset,
        caretColor: AppColors.of(context).primary,
        onTapOffset: onTapOffset,
        semanticsLabel: semanticsLabel,
        liveRegion: liveRegion,
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDisplayText renderObject,
  ) {
    renderObject
      ..text = text
      ..style = style
      ..color = color
      ..minScale = minScale
      ..caretOffset = caretOffset
      ..caretColor = AppColors.of(context).primary
      ..onTapOffset = onTapOffset
      ..semanticsLabel = semanticsLabel
      ..liveRegion = liveRegion
      ..textScaler = MediaQuery.textScalerOf(context)
      ..textDirection = Directionality.of(context);
  }
}

/// The render object of [DisplayText].
class RenderDisplayText extends RenderBox {
  /// Creates the render object; see [DisplayText] for the parameters.
  RenderDisplayText({
    required this._text,
    required this._style,
    required this._color,
    required this._minScale,
    required this._caretOffset,
    required this._caretColor,
    required this._onTapOffset,
    required this._semanticsLabel,
    required this._liveRegion,
    required this._textScaler,
    required this._textDirection,
  });

  static const double _caretWidth = 2;

  /// Attempts at finding the scale at which the text fits on one line.
  /// Scaling is close to linear, so two usually suffice.
  static const int _fitAttempts = 4;

  final TextPainter _painter = TextPainter(textAlign: TextAlign.end);
  late final TapGestureRecognizer _tap = TapGestureRecognizer(debugOwner: this)
    ..onTapUp = _handleTapUp;
  double _fontScale = 1;

  /// The scale the text is drawn at, from `minScale` to 1.
  double get fontScale => _fontScale;

  String _text;
  set text(String value) {
    if (value == _text) return;
    _text = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  TextStyle _style;
  set style(TextStyle value) {
    if (value == _style) return;
    _style = value;
    markNeedsLayout();
  }

  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsLayout();
  }

  double _minScale;
  set minScale(double value) {
    if (value == _minScale) return;
    _minScale = value;
    markNeedsLayout();
  }

  int? _caretOffset;
  set caretOffset(int? value) {
    if (value == _caretOffset) return;
    _caretOffset = value;
    markNeedsPaint();
  }

  Color _caretColor;
  set caretColor(Color value) {
    if (value == _caretColor) return;
    _caretColor = value;
    markNeedsPaint();
  }

  ValueChanged<int>? _onTapOffset;
  set onTapOffset(ValueChanged<int>? value) => _onTapOffset = value;

  String? _semanticsLabel;
  set semanticsLabel(String? value) {
    if (value == _semanticsLabel) return;
    _semanticsLabel = value;
    markNeedsSemanticsUpdate();
  }

  bool _liveRegion;
  set liveRegion(bool value) {
    if (value == _liveRegion) return;
    _liveRegion = value;
    markNeedsSemanticsUpdate();
  }

  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (value == _textScaler) return;
    _textScaler = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  TextSpan _span(double scale) => TextSpan(
    text: _text,
    style: _style.copyWith(color: _color, fontSize: _style.fontSize! * scale),
  );

  /// Lays [painter] out for [maxWidth] at the largest scale at which the
  /// text fits on one line (at least `minScale`), and returns that scale.
  double _layoutFitted(TextPainter painter, double maxWidth) {
    painter
      ..textDirection = _textDirection
      ..textScaler = _textScaler;
    var scale = 1.0;
    for (var attempt = 0; attempt < _fitAttempts; attempt++) {
      painter
        ..text = _span(scale)
        ..layout();
      final width = painter.maxIntrinsicWidth;
      if (!maxWidth.isFinite || width <= maxWidth || scale <= _minScale) break;
      scale = math.max(_minScale, scale * maxWidth / width);
    }
    if (maxWidth.isFinite) {
      painter.layout(minWidth: maxWidth, maxWidth: maxWidth);
    }
    return scale;
  }

  Size _sizeFor(TextPainter painter, BoxConstraints constraints) =>
      constraints.constrain(
        Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : painter.width,
          painter.height,
        ),
      );

  @override
  void performLayout() {
    _fontScale = _layoutFitted(_painter, constraints.maxWidth);
    size = _sizeFor(_painter, constraints);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final painter = TextPainter(textAlign: TextAlign.end);
    try {
      _layoutFitted(painter, constraints.maxWidth);
      return _sizeFor(painter, constraints);
    } finally {
      painter.dispose();
    }
  }

  double _naturalWidth(double scale) {
    final painter = TextPainter(
      text: _span(scale),
      textDirection: _textDirection,
      textScaler: _textScaler,
    );
    try {
      return (painter..layout()).maxIntrinsicWidth;
    } finally {
      painter.dispose();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => _naturalWidth(_minScale);

  @override
  double computeMaxIntrinsicWidth(double height) => _naturalWidth(1);

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  void paint(PaintingContext context, Offset offset) {
    _painter.paint(context.canvas, offset);
    final caretOffset = _caretOffset;
    if (caretOffset == null) return;
    final position = TextPosition(offset: caretOffset.clamp(0, _text.length));
    final caret = _painter.getOffsetForCaret(position, Rect.zero);
    final height = _painter.getFullHeightForCaret(position, Rect.zero);
    final left = (caret.dx - _caretWidth / 2).clamp(
      0.0,
      math.max(0, size.width - _caretWidth),
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          offset.dx + left,
          offset.dy + caret.dy,
          _caretWidth,
          height,
        ),
        const Radius.circular(_caretWidth / 2),
      ),
      Paint()..color = _caretColor,
    );
  }

  @override
  bool hitTestSelf(Offset position) => _onTapOffset != null;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && _onTapOffset != null) {
      _tap.addPointer(event);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final local = globalToLocal(details.globalPosition);
    _onTapOffset?.call(_painter.getPositionForOffset(local).offset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..label = _semanticsLabel ?? _text
      ..textDirection = _textDirection
      ..liveRegion = _liveRegion;
  }

  @override
  void dispose() {
    _tap.dispose();
    _painter.dispose();
    super.dispose();
  }
}
