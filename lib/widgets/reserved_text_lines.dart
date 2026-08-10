import 'package:flutter/material.dart';

/// Reserves vertical space for [lines] lines of text so cards laid out side by
/// side agree on where everything below the text sits.
///
/// ## Why a floor and not a fixed height
///
/// `maxLines: 2` only CAPS a label — a one-line name still collapses the block
/// and drags the price row up with it, so two cards in a rail disagree. The
/// obvious fix, `SizedBox(height: fontSize * lineHeight * lines)`, is worse: a
/// tight box is only exactly N lines if the arithmetic matches the rendered
/// text to the pixel, and it doesn't. The system text scale is unclamped in
/// this app, and font metrics round. Whenever the real lines came out a hair
/// taller than the box, the `Text` clipped and the last line vanished.
///
/// A `minHeight` gives short labels the same reserved space (the slack falls to
/// the bottom, which is what you want) and simply grows rather than cutting
/// when the text genuinely needs more.
///
/// [fontSize] must match the child's own font size, and [lineHeight] its
/// `TextStyle.height`, or the reservation won't line up with what renders.
class ReservedTextLines extends StatelessWidget {
  const ReservedTextLines({
    super.key,
    required this.fontSize,
    required this.child,
    this.lines = 2,
    this.lineHeight = 1.3,
  });

  final double fontSize;
  final int lines;
  final double lineHeight;
  final Widget child;

  /// Reserved height at the device's CURRENT text scale.
  static double heightOf(
    BuildContext context, {
    required double fontSize,
    int lines = 2,
    double lineHeight = 1.3,
  }) =>
      MediaQuery.textScalerOf(context).scale(fontSize) * lineHeight * lines;

  /// Reserved height at scale 1.0 — for the static `gridCardHeight` getters,
  /// which are read without a context and apply the scale themselves.
  static double unscaledHeight({
    required double fontSize,
    int lines = 2,
    double lineHeight = 1.3,
  }) =>
      fontSize * lineHeight * lines;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: heightOf(
          context,
          fontSize: fontSize,
          lines: lines,
          lineHeight: lineHeight,
        ),
        minWidth: double.infinity,
      ),
      child: child,
    );
  }
}
