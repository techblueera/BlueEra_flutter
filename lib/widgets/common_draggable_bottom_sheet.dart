import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class CommonDraggableBottomSheet extends StatelessWidget {
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final Widget Function(ScrollController scrollController) builder;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;

  const CommonDraggableBottomSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.6,
    this.minChildSize = 0.4,
    this.maxChildSize = 0.95,
    this.backgroundColor = AppColors.white,
    this.padding,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(10)),
    this.boxShadow
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            boxShadow: boxShadow ?? null
          ),
          padding: padding ?? EdgeInsets.only(top: SizeConfig.size15),
          child: builder(scrollController),
        );
      },
    );
  }
}
