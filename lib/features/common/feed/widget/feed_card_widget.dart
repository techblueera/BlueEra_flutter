import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/glass_surface.dart';
import 'package:flutter/material.dart';

class FeedCardWidget extends StatelessWidget {
  const FeedCardWidget(
      {super.key, required this.childWidget, this.horizontalPadding, this.bottomPadding});

  final Widget childWidget;
  final double? horizontalPadding;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    // Under a [GlassScope] — the Connect screen — the card is translucent so
    // the app-wide banner reads through it. Everywhere else this widget is used
    // (post detail, the repost composer, profile overview) it stays the solid
    // white card those screens are built around.
    final bool glass = GlassScope.isActive(context);
    final radius = BorderRadius.circular(20);

    return Container(
      margin: EdgeInsets.only(
          bottom: bottomPadding??SizeConfig.paddingXSL,
          left: horizontalPadding ?? SizeConfig.paddingXS,
          right: horizontalPadding ?? SizeConfig.paddingXS
      ),
      // Clip content to the rounded corners and add a hairline border + soft
      // shadow so the card keeps crisp, defined edges on ANY background —
      // the app-wide banner/colour now shows in the gaps around it.
      clipBehavior: Clip.antiAlias,
      decoration: !glass
          ? glassDecoration(borderRadius: radius)
          : BoxDecoration(
          color: AppColors.white,
          borderRadius: radius,
          border: Border.all(color: AppColors.greyE5, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
      ),
      child: childWidget,
    );
  }
}
