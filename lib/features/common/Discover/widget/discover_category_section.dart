import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
            fontSize: SizeConfig.small11,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w400,
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
    // Landing grid (see [DiscoverFolderScope]): collapse to a folder tile whose
    // sheet re-renders this very card, so routing below is untouched.
    if (DiscoverFolderScope.isActive(context)) {
      // Prefer the owning section widget so the sheet gets a live instance of
      // it — see [DiscoverFolderHost]. Falls back to this card when the section
      // IS this widget (grocery / food / home services are listed directly).
      final host = DiscoverFolderHost.sectionOf(context);
      return DiscoverFolderTile(
        title: title,
        iconPaths: items.map((e) => e.icon ?? '').toList(),
        expandedBuilder: (_) => host ?? _fullCard(),
      );
    }
    return _fullCard();
  }

  Widget _fullCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),

        color: AppColors.white,

      ),
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

/// A single round category tile that reads its label + icon from raw strings
/// (rather than a [CollapsibleGridModel]). Supports both bundled asset icons
/// and network URLs, so every Discover service section can share the same
/// circular look regardless of where its icon comes from.
class DiscoverIconTile extends StatelessWidget {
  final String name;
  final String iconPath;
  final VoidCallback onTap;
  final double diameter;

  const DiscoverIconTile({
    super.key,
    required this.name,
    required this.iconPath,
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
            child: _buildIcon(),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            name,
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

  Widget _buildIcon() {
    if (iconPath.isEmpty) return const SizedBox.shrink();
    if (isNetworkImage(iconPath)) {
      return CachedNetworkImage(
        imageUrl: iconPath,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.secondaryTextColor,
          size: 20,
        ),
      );
    }
    return LocalAssets(imagePath: iconPath, boxFix: BoxFit.contain);
  }
}

/// Generic version of [DiscoverCategorySection] for the redesigned Discover
/// service sections. Renders a bold title (+ optional "View All") over a grid
/// of circular [DiscoverIconTile]s, [columns]-per-row, reading each tile's
/// label / icon / tap from the supplied callbacks so any model type can be
/// laid out with the same look while its existing routing stays untouched.
class DiscoverGridSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final int columns;
  final String Function(T item) getName;
  final String Function(T item) getIcon;
  final void Function(T item) onItemTap;
  final VoidCallback? onViewAll;
  final String? viewAllLabel;

  const DiscoverGridSection({
    super.key,
    required this.title,
    required this.items,
    required this.getName,
    required this.getIcon,
    required this.onItemTap,
    this.columns = 5,
    this.onViewAll,
    this.viewAllLabel,
  });

  @override
  Widget build(BuildContext context) {
    // See [DiscoverCategorySection.build] — same folder collapse, same reason.
    if (DiscoverFolderScope.isActive(context)) {
      final host = DiscoverFolderHost.sectionOf(context);
      return DiscoverFolderTile(
        title: title,
        iconPaths: items.map(getIcon).toList(),
        expandedBuilder: (_) => host ?? _fullCard(),
      );
    }
    return _fullCard();
  }

  Widget _fullCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),      padding: EdgeInsets.symmetric(
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
              if (onViewAll != null)
                ViewAllButton(onTap: onViewAll!, label: viewAllLabel),
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
                        child: DiscoverIconTile(
                          name: getName(item),
                          iconPath: getIcon(item),
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
