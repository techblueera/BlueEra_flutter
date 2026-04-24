import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

/// One stat cell rendered inside [DiscoverStatsRow].
class DiscoverStatItem {
  /// Path to a local asset (SVG/PNG). Rendered via [LocalAssets].
  final String icon;
  final String count;
  final String label;
  final Color iconColor;
  final Color iconBgColor;

  /// Optional tap handler. When provided, the stat becomes a proper ripple
  /// target with an `InkWell`.
  final VoidCallback? onTap;

  const DiscoverStatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.iconColor,
    required this.iconBgColor,
    this.onTap,
  });
}

/// Horizontal row of compact stat chips used on Discover list cards (grocery,
/// product store, etc). Each cell is tappable and shows an icon badge +
/// `count` + `label`.
class DiscoverStatsRow extends StatelessWidget {
  final List<DiscoverStatItem> items;
  final double gap;

  const DiscoverStatsRow({
    super.key,
    required this.items,
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final item in items) _StatCell(item: item),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final DiscoverStatItem item;

  const _StatCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.0),
        onTap: item.onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
              horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            // Gradient lifts the chip away from the card surface — white
            // anchor on the top-left fading into the category's own tint
            // on the bottom-right.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                item.iconBgColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: item.iconColor.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: item.iconColor.withValues(alpha: 0.10),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon sits in a floating white disc so it reads as a
              // badge rather than an inline glyph.
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: item.iconColor.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: LocalAssets(
                  imagePath: item.icon,
                  imgColor: item.iconColor,
                  height: 13,
                  width: 13,
                ),
              ),
              const SizedBox(width: 8),
              CustomText(
                item.count,
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w800,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: CustomText(
                  item.label,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
