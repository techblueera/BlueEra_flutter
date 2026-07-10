import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

/// A single round category tile: an illustrated icon inside a soft circular
/// background with a 2-line label below. Mirrors the tiles in the Discover
/// redesign (Grocery / Food sections).
class DiscoverCircleTile extends StatelessWidget {
  final CollapsibleGridModel item;
  final VoidCallback onTap;
  final double diameter;

  const DiscoverCircleTile({
    super.key,
    required this.item,
    required this.onTap,
    this.diameter = 64,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: diameter,
            height: diameter,
            padding: EdgeInsets.all(diameter * 0.14),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF2F6FF),
            ),
            child: LocalAssets(
              imagePath: item.icon ?? '',
              boxFix: BoxFit.contain,
            ),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            item.name,
            textAlign: TextAlign.center,
            fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Section header (bold title on the left, optional "View All" on the right)
/// followed by a grid of [DiscoverCircleTile]s laid out [columns]-per-row.
///
/// Used for the Grocery and Food blocks of the redesigned Discover page.
class DiscoverCategorySection extends StatelessWidget {
  final String title;
  final List<CollapsibleGridModel> items;
  final int columns;
  final void Function(CollapsibleGridModel item) onItemTap;
  final VoidCallback? onViewAll;

  const DiscoverCategorySection({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    this.columns = 5,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  title,
                  fontSize: SizeConfig.large18,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onViewAll != null) ViewAllButton(onTap: onViewAll!),
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 8;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: SizeConfig.size16,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: DiscoverCircleTile(
                          item: item,
                          diameter: itemWidth * 0.9,
                          onTap: () => onItemTap(item),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
