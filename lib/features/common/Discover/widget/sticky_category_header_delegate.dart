import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A category item used by [StickyCategoryHeaderDelegate].
class StickyCategory {
  final String id;
  final String name;
  final String? imageUrl;

  const StickyCategory({
    required this.id,
    required this.name,
    this.imageUrl,
  });
}

/// Generic sticky header delegate.
/// - Normal (below banner): search bar + category tabs, no topPadding.
/// - Sticky (pinned): back button + tabs on the same gradient bg, topPadding, no search bar.
class StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final List<StickyCategory> categories;
  final String? selectedId;
  final ValueChanged<StickyCategory> onCategoryTap;
  final VoidCallback onBack;
  final bool singleLineLabel;

  /// Optional gradient painted behind the header in both states so the
  /// collapsed (sticky) header matches the expanded look.
  final Gradient? backgroundGradient;

  /// Optional label color applied to tab text — useful when
  /// [backgroundGradient] is dark. Bold weight still distinguishes the
  /// active tab.
  final Color? expandedLabelColor;

  static const double _searchBarHeight = 44;
  static const double _searchGap = 10;
  static const double _tabsHeight = 95;
  static const double _tabsHeightSingleLine = 72;
  static const double _vPad = 8;

  static const double _collapsible = _searchBarHeight + _searchGap;

  StickyCategoryHeaderDelegate({
    required this.topPadding,
    required this.categories,
    required this.selectedId,
    required this.onCategoryTap,
    required this.onBack,
    this.singleLineLabel = false,
    this.backgroundGradient,
    this.expandedLabelColor,
  });

  double get _effectiveTabsHeight =>
      singleLineLabel ? _tabsHeightSingleLine : _tabsHeight;

  @override
  double get maxExtent => _vPad + _collapsible + _effectiveTabsHeight + _vPad;

  @override
  double get minExtent => topPadding + _effectiveTabsHeight + _vPad;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final collapseRange = maxExtent - minExtent;
    final t = collapseRange <= 0
        ? 1.0
        : (shrinkOffset / collapseRange).clamp(0.0, 1.0);
    final isSticky = t >= 0.999;

    final searchHeight = (1 - t) * _collapsible;
    final searchOpacity = (1 - t * 1.5).clamp(0.0, 1.0);
    final currentTopPad = (1 - t) * _vPad + t * topPadding;

    return ClipRect(
      child: BackdropFilter(
        // iOS-style glass: blur whatever scroll content sits behind the
        // header. When callers pass a fully opaque [backgroundGradient]
        // the blur is masked; with a translucent gradient the frosted
        // look shows through.
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
      decoration: BoxDecoration(gradient: backgroundGradient),
      child: Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(top: currentTopPad),
        child: Column(
          children: [
            // Search bar (collapses away)
            SizedBox(
              height: searchHeight,
              child: ClipRect(
                child: OverflowBox(
                  minHeight: _collapsible,
                  maxHeight: _collapsible,
                  alignment: Alignment.topCenter,
                  child: Opacity(
                    opacity: searchOpacity,
                    child: IgnorePointer(
                      ignoring: searchOpacity < 0.05,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size12),
                            child: Container(
                              height: _searchBarHeight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                border: Border.all(
                                    width: 1, color: AppColors.greyE5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search,
                                      color: AppColors.secondaryTextColor,
                                      size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CustomText(
                                      AppStrings.searchAnything,
                                      fontSize: 14,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                  ),
                                  LocalAssets(
                                    imagePath: AppIconAssets.mic,
                                    width: 18,
                                    height: 18,
                                    imgColor: AppColors.secondaryTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  LocalAssets(
                                      imagePath:
                                          AppIconAssets.camera_black),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: _searchGap),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Tabs with back button when sticky
            Expanded(
              child: Row(
                children: [
                  if (isSticky)
                    Padding(
                      padding: EdgeInsets.only(
                          left: SizeConfig.size6,
                          right: SizeConfig.size6),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onBack,
                          child: Container(
                            padding: EdgeInsets.all(SizeConfig.size8),
                            decoration: BoxDecoration(
                              color: AppColors.white
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back,
                                color: AppColors.white,
                                size: SizeConfig.size20),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: isSticky ? 0 : SizeConfig.size12,
                        right: SizeConfig.size12,
                      ),
                      child: Row(
                        children: List.generate(
                            categories.length, (index) {
                          final item = categories[index];
                          final isActive = selectedId == item.id;
                          return Padding(
                            padding: EdgeInsets.only(
                                right: SizeConfig.size10),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onCategoryTap(item),
                              child: SizedBox(
                                width: SizeConfig.size65,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: SizeConfig.size48,
                                      height: SizeConfig.size48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? null
                                            : AppColors.white,
                                        gradient: isActive
                                            ? const LinearGradient(
                                                begin: Alignment
                                                    .topCenter,
                                                end: Alignment
                                                    .bottomCenter,
                                                colors: [
                                                  AppColors.white,
                                                  Color(0xFFA4D4FF),
                                                ],
                                              )
                                            : null,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isActive
                                              ? AppColors.primaryColor
                                              : AppColors.greyE5,
                                        ),
                                      ),
                                      child: _buildCategoryIcon(
                                          item.imageUrl),
                                    ),
                                    SizedBox(height: SizeConfig.size4),
                                    Container(
                                      height: singleLineLabel
                                          ? SizeConfig.small * 1.6
                                          : SizeConfig.small * 3.4,
                                      alignment: Alignment.topCenter,
                                      child: CustomText(
                                        singleLineLabel
                                            ? item.name
                                            : (item.name).replaceFirst(
                                                ' ', '\n'),
                                        fontSize: SizeConfig.small,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: expandedLabelColor ??
                                            (isActive
                                                ? AppColors.primaryColor
                                                : AppColors
                                                    .secondaryTextColor),
                                        maxLines:
                                            singleLineLabel ? 1 : 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: _vPad),
          ],
        ),
      ),
      ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(
        Icons.category_outlined,
        size: SizeConfig.size30,
        color: AppColors.secondaryTextColor,
      );
    }
    // Network image (http/https)
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: SizeConfig.size30,
        height: SizeConfig.size30,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          width: SizeConfig.size30,
          height: SizeConfig.size30,
        ),
        errorWidget: (_, __, ___) => Icon(
          Icons.category_outlined,
          size: SizeConfig.size30,
          color: AppColors.secondaryTextColor,
        ),
      );
    }
    // Local asset
    return LocalAssets(
      imagePath: imageUrl,
      width: SizeConfig.size30,
      height: SizeConfig.size30,
      boxFix: BoxFit.cover,
    );
  }

  @override
  bool shouldRebuild(
          covariant StickyCategoryHeaderDelegate oldDelegate) =>
      topPadding != oldDelegate.topPadding ||
      categories != oldDelegate.categories ||
      selectedId != oldDelegate.selectedId ||
      onCategoryTap != oldDelegate.onCategoryTap ||
      onBack != oldDelegate.onBack ||
      backgroundGradient != oldDelegate.backgroundGradient ||
      expandedLabelColor != oldDelegate.expandedLabelColor;
}
