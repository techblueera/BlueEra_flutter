import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/circle_icon_grid_item.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollapsibleGridSection extends StatefulWidget {
  final String title;
  final List<CollapsibleGridModel> categories;
  final void Function(CollapsibleGridModel item)? onTap;

  const CollapsibleGridSection({
    super.key,
    required this.title,
    required this.categories,
    this.onTap,
  });

  @override
  State<CollapsibleGridSection> createState() => _CollapsibleGridSectionState();
}

class _CollapsibleGridSectionState extends State<CollapsibleGridSection> {
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);

  static const int crossAxisCount = 4;
  static const double mainAxisSpacing = 16.0;

  List<Widget> _buildRows(List<CollapsibleGridModel> source) {
    final rows = <List<CollapsibleGridModel>>[];

    for (int i = 0; i < source.length; i += crossAxisCount) {
      rows.add(
        source.sublist(i, (i + crossAxisCount).clamp(0, source.length)),
      );
    }

    return rows.map((rowItems) {
      return Padding(
        padding: const EdgeInsets.only(bottom: mainAxisSpacing),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(crossAxisCount * 2 - 1, (i) {
            if (i.isEven) {
              final index = i ~/ 2;

              return Expanded(
                child: index < rowItems.length
                    ? CircleIconGridItem(
                  label: rowItems[index].label,
                  icon: 'assets/category/grocery/${rowItems[index].icon}',
                  onTap: () => widget.onTap?.call(rowItems[index]),
                )
                    : const SizedBox.shrink(),
              );
            } else {
              return SizedBox(width: SizeConfig.size20);
            }
          }),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final firstEight = widget.categories.take(8).toList();
    final remaining = widget.categories.skip(8).toList();
    final hasMore = remaining.isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (_, expanded, __) {
        final visibleList = expanded ? widget.categories : firstEight;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomText(
                    widget.title,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  const Spacer(),
                  if (hasMore)
                    InkWell(
                      onTap: () => isExpanded.value = !isExpanded.value,
                      child: CustomText(
                        expanded ? 'See Less'.tr : 'See More'.tr,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Grid Rows
              Column(children: _buildRows(visibleList)),
            ],
          ),
        );
      },
    );
  }
}
