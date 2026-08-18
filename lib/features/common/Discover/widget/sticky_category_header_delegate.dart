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

  /// Font size for the tab labels, before the width-based responsive scale.
  ///
  /// Defaults to [SizeConfig.small]. Screens whose category names run long can
  /// pass a smaller step (e.g. [SizeConfig.small11]). The value is uniform:
  /// EVERY tab on a given screen renders at the same size — a label that does
  /// not fit wraps to a second line and then ellipsizes, it is never shrunk to
  /// fit. Per-label shrinking is what made the strip look ragged, with a short
  /// name printed large next to a long one printed small.
  final double? labelFontSize;

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
    this.labelFontSize,
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
    // One size for the whole strip. It follows the device (SizeConfig's
    // phone/tablet step, then the same narrow-screen `scale` as the tiles) but
    // never the individual label, and is floored so the narrow-screen scale
    // can't take it below what still reads at arm's length.
    final double minLabelFontSize = SizeConfig.isTablet ? 12.0 : 9.5;
    final double effectiveLabelFontSize =
        ((labelFontSize ?? SizeConfig.small) * scale)
            .clamp(minLabelFontSize, double.infinity)
            .toDouble();
    final double labelLineHeight = effectiveLabelFontSize * 1.25;

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
                                              width: 1,
                                              color: AppColors.greyE5),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.search,
                                                color: AppColors
                                                    .secondaryTextColor,
                                                size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: CustomText(
                                                AppStrings.searchAnything,
                                                fontSize: 14,
                                                color: AppColors
                                                    .secondaryTextColor,
                                              ),
                                            ),
                                            LocalAssets(
                                              imagePath: AppIconAssets.mic,
                                              width: 18,
                                              height: 18,
                                              imgColor:
                                                  AppColors.secondaryTextColor,
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
                                children:
                                    List.generate(categories.length, (index) {
                                  final item = categories[index];
                                  final isActive = selectedId == item.id;
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
                                              // Wraps on its own — no hand-inserted
                                              // newline. Breaking at the FIRST space
                                              // put "New Vehicle" alone on line two,
                                              // wider than the tile; letting the text
                                              // engine choose gives "All New" /
                                              // "Vehicle" instead. Two lines is the
                                              // ceiling, and anything still too long
                                              // (or a single unbreakable word) ends
                                              // in an ellipsis rather than shrinking.
                                              child: CustomText(
                                                item.name,
                                                fontSize:
                                                    effectiveLabelFontSize,
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
                                                overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  /// The artwork inside a category tab, sized to FILL the tile.
  ///
  /// It used to be pinned to 30px inside a 48px tile, leaving a ~9px white
  /// margin on every side. That margin was right when the icons were bare
  /// transparent glyphs needing a plate to sit on — the `/category` art now
  /// ships with its own tinted rounded square baked in, so the plate became a
  /// second background around the first, and each tab read as a small coloured
  /// square marooned in a white one.
  ///
  /// Filling the tile also buys the illustration 60% more area in a strip where
  /// it only ever gets 48px to identify itself.
  ///
  /// ## CONTAIN, not cover
  ///
  /// The art reaching this widget is mixed and cannot be told apart from its
  /// path: some categories ship a square with the tint baked in, others are
  /// still bare transparent cut-outs, and BOTH shapes arrive over the same
  /// `/category` URLs (see docs/discover_dynamic_icons.txt). `cover` would suit
  /// the first and crop the second. `contain` serves both — a square source
  /// fills a square tile exactly, so the baked art still goes edge to edge,
  /// while a cut-out scales to fit with nothing sliced off.
  ///
  /// Only the FALLBACK stays inset: a Material glyph is not artwork and would
  /// look stretched edge to edge.
  Widget _buildCategoryIcon(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return _fallbackIcon();

    // Network image (http/https)
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        // Nothing while loading — the tile's own surface is already the right
        // shape and colour, so a spinner here would flash on every scroll.
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => _fallbackIcon(),
      );
    }
    // Local asset
    return LocalAssets(
      imagePath: imageUrl,
      width: double.infinity,
      height: double.infinity,
      boxFix: BoxFit.contain,
    );
  }

  Widget _fallbackIcon() => Center(
        child: Icon(
          Icons.category_outlined,
          size: SizeConfig.size24,
          color: AppColors.secondaryTextColor,
        ),
      );

  @override
  bool shouldRebuild(covariant StickyCategoryHeaderDelegate oldDelegate) =>
      topPadding != oldDelegate.topPadding ||
      categories != oldDelegate.categories ||
      selectedId != oldDelegate.selectedId ||
      onCategoryTap != oldDelegate.onCategoryTap ||
      onBack != oldDelegate.onBack ||
      backgroundGradient != oldDelegate.backgroundGradient ||
      expandedLabelColor != oldDelegate.expandedLabelColor ||
      onSearchTap != oldDelegate.onSearchTap ||
      labelFontSize != oldDelegate.labelFontSize;
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
  /// Ring + glow on the selected tab. One constant so the outline and the light
  /// it throws can't drift apart.
  static const Color _kActiveRing = AppColors.yellow00;

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
        // Clipped, because the artwork now fills the tile — without this a
        // square image would paint over the rounded corners.
        clipBehavior: Clip.antiAlias,
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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: g,
            borderRadius: BorderRadius.circular(12),
            // AMBER, not white. The ring is the whole active cue now that
            // artwork fills the tile and hides the gradient behind it — and a
            // white ring had two things working against it here: the header it
            // sits on is a pale-to-mid blue, and most of the category art is
            // itself light, so the ring was low-contrast on both sides at once.
            // A warm accent is the one hue neither the blue chrome nor the
            // illustrations occupy, so it reads as "chosen" at a glance without
            // competing with the picture it frames.
            border: Border.all(color: _kActiveRing, width: 2.5),
            boxShadow: [
              // Amber glow so the tile reads as lit rather than merely outlined,
              // over the dark grounding shadow that lifts it off the header.
              BoxShadow(
                color: _kActiveRing.withValues(alpha: 0.45),
                blurRadius: 10,
                spreadRadius: 0.5,
              ),
              const BoxShadow(
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
