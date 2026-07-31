import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/recent_shops_controller.dart';
import 'package:BlueEra/features/common/Discover/model/recent_shops_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Uniform store-card dimensions — shared by the card, its shimmer, and the
/// carousel row height so every card is the same size and the row never leaves
/// dead space below the cards.
const double _kCardWidth = 185;
const double _kCardHeight = 254;
const double _kCardImageHeight = 105;

/// Carousel row height = exactly the card height, so the space above the row
/// (title gap) and below it (section padding) stay symmetric. The card's drop
/// shadow is allowed to paint past the row via the list's `Clip.none`.
const double _kRowHeight = _kCardHeight;

/// ─── Glass tokens ───────────────────────────────────────────────────────────
/// Same frosted language as the rest of the redesigned Discover page (see
/// `recent_orders_section.dart` and [DiscoverFolderTile]): a translucent white
/// wash over the app background rather than a solid card, a bright hairline
/// border for the pane's edge, and a lift shadow underneath.
///
/// No [BackdropFilter] anywhere — Discover deliberately avoids per-frame blur on
/// this page (it forces a save-layer over a scrolling sliver list and has been
/// reverted twice); the frosted read comes from plain alpha.

/// Lift under a translucent panel. A glass pane has no fill of its own to
/// separate it from the background, so the shadow is what makes it float.
const List<BoxShadow> _kGlassShadow = [
  BoxShadow(
    color: Color(0x1F101828),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Color(0x14101828),
    blurRadius: 4,
    offset: Offset(0, 1),
  ),
];

/// Tighter contact shadow for the cards sitting ON the panel — glass-on-glass,
/// so the lift has to be smaller than the panel's own or the two pile up.
const List<BoxShadow> _kGlassCardShadow = [
  BoxShadow(
    color: Color(0x14101828),
    blurRadius: 10,
    offset: Offset(0, 4),
  ),
];

/// Horizontally scrolling carousel of the user's recently-visited stores
/// ("order again"). Backed by [RecentShopsController], which compiles the
/// grocery / product / food `recent-shops` endpoints. Hidden entirely when the
/// user has no recent shops. See docs/backend/RECENT_SHOPS_FLUTTER_INTEGRATION.md.
class RecentlyVisitedStoresSection extends StatefulWidget {
  final VoidCallback? onViewAll;
  final void Function(RecentShop store)? onStoreTap;

  const RecentlyVisitedStoresSection({
    super.key,
    this.onViewAll,
    this.onStoreTap,
  });

  @override
  State<RecentlyVisitedStoresSection> createState() =>
      _RecentlyVisitedStoresSectionState();
}

class _RecentlyVisitedStoresSectionState
    extends State<RecentlyVisitedStoresSection> {
  final _controller = getOrPut(() => RecentShopsController());

  @override
  void initState() {
    super.initState();
    _controller.fetchIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = _controller.isLoading.value && _controller.shops.isEmpty;
      final shops = _controller.shops;

      // Loaded with nothing → hide the section (no empty card).
      if (_controller.loaded.value && !loading && shops.isEmpty) {
        return const SizedBox.shrink();
      }

      // Glass panel matching the rest of the redesigned Discover page. It lives
      // INSIDE the widget (not in the parent's wrapper) so an empty rail still
      // collapses to SizedBox.shrink() above — no leftover pane or gap. The
      // bottom margin gives the same inter-section spacing the folders get.
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          boxShadow: _kGlassShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              child: Row(
                children: [
                  Expanded(
                    // White, like the other glass-panel headings: the title sits
                    // on the translucent pane, which carries the background
                    // through — dark ink on it reads as a smudge on a photo.
                    child: CustomText(
                      AppStrings.recentlyVisitedStores.tr,
                      fontSize: SizeConfig.large18,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.onViewAll != null)
                    _GlassViewAllButton(onTap: widget.onViewAll!),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size14),
            SizedBox(
              height: _kRowHeight,
              child: loading
                  ? _loadingRow()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                      itemCount: shops.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: SizeConfig.size12),
                      itemBuilder: (context, index) => _StoreCard(
                        shop: shops[index],
                        onTap: () => widget.onStoreTap?.call(shops[index]),
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _loadingRow() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size12),
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  /// Store-card shaped shimmer skeleton (image block + name/location lines + two
  /// stat chips). A transparent outer box so only the grey shapes shimmer, with
  /// gaps between them.
  Widget _shimmerCard() {
    return buildLoadingShimmer(
      child: SizedBox(
        width: _kCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shimmerContainer(
                height: _kCardImageHeight, width: _kCardWidth, radius: 18),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shimmerContainer(height: 14, width: 120, radius: 4),
                  const SizedBox(height: 7),
                  shimmerContainer(height: 10, width: 80, radius: 4),
                  const SizedBox(height: 12),
                  shimmerContainer(height: 30, width: 118, radius: 9),
                  const SizedBox(height: 6),
                  shimmerContainer(height: 30, width: 132, radius: 9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "View All" as a frosted pill instead of the pale-blue [ViewAllButton] chip.
///
/// That chip's fill is `primaryColor.withAlpha(10)` — near-invisible on a
/// translucent pane, which has no white card behind it to sit on. A high-alpha
/// white plate gives the link its own surface and keeps the brand-blue label
/// legible whatever background the user picked.
class _GlassViewAllButton extends StatelessWidget {
  const _GlassViewAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: CustomText(
            AppStrings.viewAll,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final RecentShop shop;
  final VoidCallback onTap;

  const _StoreCard({required this.shop, required this.onTap});

  /// Compact count: 10 → "10", 10000 → "10K", 250000 → "2.5L".
  String _compact(int n) {
    if (n >= 100000) {
      return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)}L';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return '$n';
  }

  /// "X Km Away" computed from the shop coords + the user's current location;
  /// falls back to the city/address line when either coordinate is unavailable.
  String? _distanceOrLocation(BusinessSummary? biz, String location) {
    final lat = biz?.lat;
    final lon = biz?.lon;
    final ulat = LocationService.lat;
    final ulng = LocationService.lng;
    if (lat != null &&
        lon != null &&
        !(lat == 0 && lon == 0) &&
        !(ulat == 0 && ulng == 0)) {
      final km = Geolocator.distanceBetween(ulat, ulng, lat, lon) / 1000;
      final text = km < 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(0);
      return '$text Km Away';
    }
    return location.isNotEmpty ? location : null;
  }

  @override
  Widget build(BuildContext context) {
    final biz = shop.business;
    final logo = biz?.logo ?? '';
    final location = (biz?.cityStatePincode?.isNotEmpty ?? false)
        ? biz!.cityStatePincode!
        : (biz?.address ?? '');
    final subLine = _distanceOrLocation(biz, location);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: _kCardWidth,
        height: _kCardHeight,
        decoration: BoxDecoration(
          // Frosted plate on the panel — glass on glass. Kept at a high alpha
          // (unlike the panel's 0.10) because this card is dense dark text: a
          // shop name, a distance and two stat rows need a surface to sit on,
          // not a tint.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.72),
              Colors.white.withValues(alpha: 0.58),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: _kGlassCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Cover image + rating pill + chat button ───
            Stack(
              children: [
                ClipRRect(
                  // One less than the card's 18 — the inner edge of a 1px
                  // border, so no sliver of image creeps past the corner.
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(17)),
                  child: logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: logo,
                          height: _kCardImageHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imageFallback(),
                          errorWidget: (_, __, ___) => _imageFallback(),
                        )
                      : _imageFallback(),
                ),
                if (biz?.avgRating != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        // Frosted, not solid — but only slightly: these two
                        // badges sit on the shop's own photo, which can be any
                        // colour, so they keep most of their fill.
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.6)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A101828),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFB300), size: 13),
                          const SizedBox(width: 2),
                          CustomText(
                            biz!.avgRating!.toStringAsFixed(1),
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A101828),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LocalAssets(
                      imagePath: AppIconAssets.chat,
                      height: 15,
                      width: 15,
                      imgColor: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            // ─── Name → distance → dashed divider → stacked stat pills ───
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      shop.displayName,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subLine != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: AppColors.primaryColor),
                          const SizedBox(width: 2),
                          Expanded(
                            child: CustomText(
                              subLine,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const _DashedDivider(),
                    const SizedBox(height: 8),
                    _StatRow(
                      iconAsset: AppIconAssets.staggeredIcon,
                      iconColor: const Color(0xFF9964F4),
                      value: _compact(shop.orderCount),
                      label: 'Orders',
                    ),
                    const SizedBox(height: 6),
                    _StatRow(
                      iconAsset: AppIconAssets.productCartIcon,
                      iconColor: const Color(0xFF6179CD),
                      value: _compact(shop.distinctProducts),
                      label: 'Products',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// No-logo placeholder. Translucent so the card stays glass all the way to
  /// its top edge instead of turning into a solid block when a shop has no
  /// picture — which, on this rail, is common.
  Widget _imageFallback() => Container(
        height: _kCardImageHeight,
        width: double.infinity,
        color: AppColors.lightBlue.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: const Icon(Icons.storefront_outlined,
            size: 34, color: AppColors.primaryColor),
      );
}

/// One compact stat pill that HUGS its content (icon + value + label),
/// left-aligned — a tinted rounded-square branded icon in a hairline-bordered
/// rounded rectangle. Matches the reference's stacked "Category / Product" rows.
class _StatRow extends StatelessWidget {
  final String iconAsset;
  final Color iconColor;
  final String value;
  final String label;

  const _StatRow({
    required this.iconAsset,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        // Third layer of glass (background → panel → card → pill), so it is the
        // brightest of the three: a plate this small needs its edge to read at
        // a glance, and a hairline grey border doesn't survive on translucency.
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
      ),
      // Hugs its content — NOT full width.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: LocalAssets(
              imagePath: iconAsset,
              width: 13,
              height: 13,
              imgColor: iconColor,
            ),
          ),
          const SizedBox(width: 7),
          CustomText(
            value,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(width: 4),
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

/// Thin full-width dashed rule separating the identity block from the stats.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashGap = 3.0;
        final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            // Lighter than the old solid `0xFFDDE2EC`: on a translucent plate a
            // hard grey rule reads as a scratch, an alpha one as a seam.
            (_) => Container(
              width: dashWidth,
              height: 1,
              color: const Color(0x33101828),
            ),
          ),
        );
      },
    );
  }
}
