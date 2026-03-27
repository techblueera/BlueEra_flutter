import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';

class GridIconImageWidget<T> extends StatelessWidget {
  final List<T>? items;
  final Function(T) getName;
  final Function(T) getIcon;
  final Function(T) onTap;
  final int crossAxisCount;

  const GridIconImageWidget(
      {super.key,
      this.items,
      required this.getName,
      required this.getIcon,
      required this.onTap,
      required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    final list = items ?? [];
    return LayoutBuilder(builder: (context, constraints) {
      const double spacing = 6;
      final double itemWidth =
          (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: list.map((item) => SizedBox(
          width: itemWidth,
          child: CommonServiceCard(
            service: item,
            getName: (i) => getName(i),
            getIcon: (i) => getIcon(i),
            iconHeight: SizeConfig.size60,
            onTap: (i) => onTap(i),
          ),
        )).toList(),
      );
    });
  }
}
