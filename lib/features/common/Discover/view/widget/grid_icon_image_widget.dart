import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: items?.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var item = items?[index];
        return CommonServiceCard(
          service: item,
          getName: (item) => getName(item as T),
          getIcon: (item) => getIcon(item as T),
          iconHeight: SizeConfig.size60,
          onTap: (item) => onTap(item as T),
        );
      },
    );
  }
}
