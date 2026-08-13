import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A horizontal dashed rule.
///
/// Used on the poll card to separate the question block from the byline — a
/// solid [Divider] there reads as a hard cut between two cards rather than as
/// a seam inside one.
class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    this.color,
    this.dashWidth = 4,
    this.dashGap = 4,
    this.thickness = 1,
  });

  final Color? color;
  final double dashWidth;
  final double dashGap;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lay the dashes out against the measured width rather than a guess,
        // so the run ends flush with the card instead of clipping mid-dash.
        final span = dashWidth + dashGap;
        final count =
            span <= 0 ? 0 : (constraints.maxWidth / span).floor().clamp(0, 400);

        return SizedBox(
          height: thickness,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => SizedBox(
                width: dashWidth,
                height: thickness,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color ?? AppColors.greyE5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
