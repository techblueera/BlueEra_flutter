import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/circle_icon_grid_item.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollapsibleGridSection<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final String Function(T item)? itemIconBuilder;
  final void Function(T item)? onTap;

  const CollapsibleGridSection({
    super.key,
    required this.title,
    required this.items,
    required this.itemLabelBuilder,
    this.itemIconBuilder,
    this.onTap,
  });

  @override
  State<CollapsibleGridSection<T>> createState() => _CollapsibleGridSectionState<T>();
}

class _CollapsibleGridSectionState<T> extends State<CollapsibleGridSection<T>> {
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);

  static const int crossAxisCount = 4;

  List<Widget> _buildRows(List<T> source) {
    final rows = <List<T>>[];

    for (int i = 0; i < source.length; i += crossAxisCount) {
      rows.add(
        source.sublist(i, (i + crossAxisCount).clamp(0, source.length)),
      );
    }

    return rows.map((rowItems) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(crossAxisCount, (index) {
            if (index < rowItems.length) {
              final item = rowItems[index];
              return Expanded(
                child: CircleIconGridItem(
                  label: widget.itemLabelBuilder(item),
                  icon: widget.itemIconBuilder?.call(item) ?? "",
                  onTap: () => widget.onTap?.call(item),
                ),
              );
            } else {
              return const Expanded(child: SizedBox());
            }
          }).expand((widget) => [widget, const SizedBox(width: 10)]).take(crossAxisCount * 2 - 1).toList(),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final firstEight = widget.items.take(8).toList();
    final remaining = widget.items.skip(8).toList();
    final hasMore = remaining.isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (_, expanded, __) {
        final visibleList = expanded ? widget.items : firstEight;

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
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        expanded ? AppStrings.seeLess.tr : AppStrings.seeMore.tr,
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
