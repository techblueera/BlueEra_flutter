import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_sections_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The horizontal rail under "Shops Near Me" / "Services Near Me".
///
/// One tile per nearby BUSINESS: its own photo, its real name, and its category
/// underneath — "highway dhaba" over "General Store", exactly as the design
/// draws it.
///
/// The endpoint groups these under categories, and that grouping is what sets
/// the ORDER (category `rank`, then the server's order inside each). The
/// flatten in `NearbyStoresController.shopBusinesses` preserves that sequence
/// rather than re-sorting by distance, so the backend's ranking survives.
class DiscoverNearMeRail extends StatelessWidget {
  const DiscoverNearMeRail({
    super.key,
    required this.items,
    required this.onTap,
    this.maxItems = 12,
  });

  final List<NearbySectionItem> items;

  /// Where a tile goes. Supplied by the screen rather than decided here.
  final void Function(NearbySectionItem item) onTap;

  /// The rail is a teaser; the full set lives behind "View All". Capping also
  /// caps how many [CachedNetworkImage]s one Discover build kicks off, which
  /// matters on a cold start where every section fetches at once.
  final int maxItems;

  static const double _avatar = 62;
  static const double _itemWidth = 78;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final shown = items.length > maxItems ? items.sublist(0, maxItems) : items;

    return SizedBox(
      // Avatar + the two text lines. Measured, not guessed: a SizedBox this
      // list overflows clips the category line.
      height: _avatar + 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: shown.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _BusinessTile(
          item: shown[i],
          onTap: () => onTap(shown[i]),
        ),
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({required this.item, required this.onTap});

  final NearbySectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // dp → logo → owner avatar. See NearbySectionItem.displayImage for why in
    // that order.
    final image = item.displayImage;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: DiscoverNearMeRail._itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Container(
                width: DiscoverNearMeRail._avatar,
                height: DiscoverNearMeRail._avatar,
                // Filled BEFORE the image loads, so a slow network shows a
                // plate in the right shape rather than a hole in the rail.
                color: const Color(0xFF17233F),
                child: image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: Uri.encodeFull(image),
                        fit: BoxFit.cover,
                        width: DiscoverNearMeRail._avatar,
                        height: DiscoverNearMeRail._avatar,
                        placeholder: (_, __) => _fallback(),
                        errorWidget: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
            const SizedBox(height: 6),
            // The business's real name.
            CustomText(
              item.name,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              height: 1.15,
            ),
            const SizedBox(height: 3),
            // Its category — "Kirana Store" under "Gupta Kirana".
            CustomText(
              item.categoryName,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              height: 1.15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Center(
        child: Icon(
          // A service business gets a person; a shop gets a storefront.
          item.businessType.toLowerCase() == 'service'
              ? Icons.handyman_rounded
              : Icons.storefront_rounded,
          size: 26,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      );
}
