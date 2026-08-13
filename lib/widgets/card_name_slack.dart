import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Measures the name line(s) a product card's title did NOT need, so the card
/// can spend that space at its own BOTTOM.
///
/// ## The problem this replaces
///
/// Cards sit side by side in a rail or a grid, so they have to agree on height.
/// The old way of getting that — [ReservedTextLines], a two-line floor on the
/// TITLE — put the leftover in the middle of the card: a one-line name, then a
/// blank line, then the price. It read as a rendering fault rather than as a
/// tidy card.
///
/// This keeps the same total height and moves the hole: the title takes the
/// height it actually needs, and the caller drops a `SizedBox(height: slack)`
/// after its LAST row. One line or two, every card is the same height and the
/// blank is always at the end.
///
/// ## Why it measures
///
/// Nothing in the widget tree reports how many lines a `Text` used, so this
/// lays the same string out with a [TextPainter] and counts. The measurement
/// must match what is painted or it returns the wrong count for exactly the
/// borderline names it exists to handle, so the caller passes the same
/// [fontSize], [fontWeight], [lineHeight] and [lines] the card renders with,
/// the string goes through `.tr` (as `CustomText` does), the font family is the
/// app's, and the layout width comes from the card's own constraints minus its
/// [horizontalPadding].
///
/// Cards whose height is already fixed by their rail or grid cell do NOT need
/// this: there, simply letting the title be its natural height leaves the slack
/// at the bottom on its own. This is for rails that size to their tallest card
/// (`ProductsRail(sizeToContent: true)`), where a shorter card really would be
/// shorter and leave the rail ragged.
class CardNameSlack extends StatelessWidget {
  const CardNameSlack({
    super.key,
    required this.text,
    required this.fontSize,
    required this.builder,
    this.lines = 2,
    this.lineHeight = 1.3,
    this.fontWeight = FontWeight.w600,
    this.horizontalPadding = 0,
  });

  /// The name exactly as the card renders it.
  final String text;

  final double fontSize;

  /// How many lines the card reserves — the title's `maxLines`.
  final int lines;

  /// The title's `TextStyle.height`. Pass null for a title that sets none, so
  /// the measurement uses the font's own metrics exactly as the render does.
  final double? lineHeight;

  final FontWeight fontWeight;

  /// Total horizontal padding between the card's edge and the title (left +
  /// right), so the measurement runs at the width the text really gets.
  final double horizontalPadding;

  /// Builds the card body with the measured slack. Put it after the last row.
  final Widget Function(BuildContext context, double slack) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth - horizontalPadding;
        // An unbounded width can't be measured against; reserving nothing is
        // the safe answer — the card is then simply its natural height, which
        // is what it would have been without any of this.
        if (!maxWidth.isFinite || maxWidth <= 0) return builder(context, 0);

        final scaler = MediaQuery.textScalerOf(context);
        final painter = TextPainter(
          text: TextSpan(
            // `.tr` because CustomText translates its title. For a product name
            // this is a passthrough, but measuring a different string than the
            // one painted is how the two drift apart.
            text: text.tr,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontWeight: fontWeight,
              fontSize: fontSize,
              height: lineHeight,
            ),
          ),
          maxLines: lines,
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout(maxWidth: maxWidth);

        final used = painter.computeLineMetrics().length.clamp(1, lines);
        // preferredLineHeight, not `fontSize * lineHeight * scale`: it is the
        // height this exact style actually lays a line out at — including the
        // text scale and the font's own metrics when no height is set — so the
        // slack matches the line that is missing rather than an approximation
        // of it.
        final perLine = painter.preferredLineHeight;
        painter.dispose();

        return builder(context, (lines - used) * perLine);
      },
    );
  }
}
