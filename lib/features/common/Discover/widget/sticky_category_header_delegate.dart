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

  /// Tap handler for the search bar. The delegate paints the bar as a
  /// non-editable affordance — callers route the tap to whatever
  /// search screen they want (e.g. an AI search overlay).
  final VoidCallback? onSearchTap;

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
    this.onSearchTap,
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

    // Responsive scaling: compact devices (~<360 logical px) were clipping
    // the tab labels. Scale tile width, icon size, and label font down
    // gracefully on narrow screens while keeping the original feel on
    // regular / large phones.
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 390).clamp(0.82, 1.0);
    final double tileWidth = SizeConfig.size65 * scale;
    final double iconTileSize = SizeConfig.size48 * scale;
    final double labelFontSize = SizeConfig.small * scale;
    final double labelLineHeight = labelFontSize * 1.25;

    return ClipRect(
      child: BackdropFilter(
        // Light glass blur. A FIXED opaque base colour sits below the gradient
        // so the header keeps its original look and does NOT depend on the
        // app-wide background (banner/colour) now painted behind every screen.
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: ColoredBox(
          color: AppColors.appBackgroundColorDefault,
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
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onSearchTap,
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
                            child: Icon(Icons.arrow_back_ios_new,
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
                          // Single-word labels can't be broken on a space,
                          // so Flutter was fragmenting the word across two
                          // lines. Treat space-less names as single-line and
                          // scale them down with FittedBox so the whole word
                          // fits inside the tile width.
                          final hasSpace = item.name.trim().contains(' ');
                          final isSingle = singleLineLabel || !hasSpace;
                          final displayName = isSingle
                              ? item.name
                              : item.name.replaceFirst(' ', '\n');
                          return Padding(
                            padding: EdgeInsets.only(
                                right: SizeConfig.size10),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onCategoryTap(item),
                              child: SizedBox(
                                width: tileWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _CategoryIconTile(
                                      size: iconTileSize,
                                      isActive: isActive,
                                      child: _buildCategoryIcon(
                                          item.imageUrl),
                                    ),
                                    SizedBox(height: SizeConfig.size4),
                                    Container(
                                      height: singleLineLabel
                                          ? labelLineHeight * 1.3
                                          : labelLineHeight * 2.7,
                                      alignment: Alignment.topCenter,
                                      child: isSingle
                                          ? FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.topCenter,
                                              child: CustomText(
                                                displayName,
                                                fontSize: labelFontSize,
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: expandedLabelColor ??
                                                    (isActive
                                                        ? AppColors
                                                            .primaryColor
                                                        : AppColors
                                                            .secondaryTextColor),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                          // Wrapping happens at the FIRST
                                          // space, so a three-word label like
                                          // "All New Vehicle" leaves "New
                                          // Vehicle" on line two — wider than
                                          // the tile, and it used to ellipsize
                                          // to "New Vehic…". Scale the block
                                          // down instead; this is a no-op for
                                          // labels that already fit.
                                          : FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.topCenter,
                                              child: CustomText(
                                                displayName,
                                                fontSize: labelFontSize,
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: expandedLabelColor ??
                                                    (isActive
                                                        ? AppColors
                                                            .primaryColor
                                                        : AppColors
                                                            .secondaryTextColor),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
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
      expandedLabelColor != oldDelegate.expandedLabelColor ||
      onSearchTap != oldDelegate.onSearchTap;
}

/// The rounded tile behind each category icon.
///
/// Inactive tiles paint a flat white surface with a grey hairline border —
/// identical to the original static design.
///
/// Active tiles cycle through a rotating set of four gradients, cross-fading
/// one into the next every three seconds. The animation lives in this
/// stateful widget (not the delegate) so its [AnimationController] survives
/// the repeated delegate rebuilds caused by header shrink-on-scroll.
class _CategoryIconTile extends StatefulWidget {
  final double size;
  final bool isActive;
  final Widget child;

  const _CategoryIconTile({
    required this.size,
    required this.isActive,
    required this.child,
  });

  @override
  State<_CategoryIconTile> createState() => _CategoryIconTileState();
}

class _CategoryIconTileState extends State<_CategoryIconTile>
    with SingleTickerProviderStateMixin {
  static const List<RadialGradient> _gradients = <RadialGradient>[
    RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [Color(0xFFC9FFB7), Color(0xFF0DA217), Color(0xFF04650B)],
    ),
    RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [Color(0xFFC0FFF9), Color(0xFF12CEBB), Color(0xFF018D7F)],
    ),
    RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [Color(0xFFE1B6FF), Color(0xFF7D0CCD), Color(0xFF3D0366)],
    ),
  ];

  late final AnimationController _ctl;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _index = (_index + 1) % _gradients.length);
          _ctl.forward(from: 0);
        }
      });
    if (widget.isActive) _ctl.forward();
  }

  @override
  void didUpdateWidget(covariant _CategoryIconTile old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_ctl.isAnimating) {
      _ctl.forward();
    } else if (!widget.isActive && _ctl.isAnimating) {
      _ctl.stop();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: widget.child,
      );
    }
    final safeIndex = _index % _gradients.length;
    final from = _gradients[safeIndex];
    final to = _gradients[(safeIndex + 1) % _gradients.length];
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, child) {
        final g = RadialGradient.lerp(from, to, _ctl.value) ?? from;
        return Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: g,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D00294E),
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
