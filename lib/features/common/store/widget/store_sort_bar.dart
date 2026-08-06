import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

/// How a near-me store list is ordered — the three chips above the list.
///
/// Applied CLIENT-SIDE. `user-service/business/search` takes page/limit/lat/lng/
/// type/category/radius and no sort parameter, so there is nothing to hand the
/// server; this reorders the pages already fetched. That is the honest limit of
/// it — "Rating" ranks the stores loaded so far, not every store in the radius,
/// and a later page can bring in a higher-rated shop that jumps up the list.
enum StoreSort {
  /// Distance from the user. Matches the order the geo search already returns,
  /// so this is the default and re-sorting is a no-op until the user moves.
  nearest,

  /// Highest `avgRating` first.
  rating,

  /// Most products first. The counts arrive on their own call after the cards
  /// are on screen, so this order settles when they land rather than at once.
  products,
}

/// [src] ordered by [sort].
///
/// Copies before sorting — the caller's list is the controller's own observable
/// and the paging code appends to it; reordering it in place would shuffle the
/// source of truth under the load-more.
List<GetAllStoreResModel> sortStores(
  List<GetAllStoreResModel> src,
  StoreSort sort,
) {
  final list = List<GetAllStoreResModel>.from(src);
  if (sort == StoreSort.rating) {
    list.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
  } else if (sort == StoreSort.products) {
    // Unknown counts sort last rather than as zero: a store whose counts
    // haven't landed is "not answered yet", and dropping it to the bottom of a
    // products ranking as if it were empty would be a claim we can't make.
    int products(GetAllStoreResModel s) =>
        storeCountsFor(s)?.productCount ?? -1;
    list.sort((a, b) => products(b).compareTo(products(a)));
  } else {
    double km(GetAllStoreResModel s) => calculateDistanceKm(
          LocationService.lat,
          LocationService.lng,
          s.businessLocation?.lat?.toDouble() ?? 0.0,
          s.businessLocation?.lon?.toDouble() ?? 0.0,
        );
    list.sort((a, b) => km(a).compareTo(km(b)));
  }
  return list;
}

/// The Nearest / Rating / Products chip row.
///
/// Single-select, always one active — these are an ORDERING, not a set of
/// predicates, so "none selected" would have no meaning (the list is always in
/// some order). Horizontally scrollable so the row survives a large text scale
/// instead of overflowing.
class StoreSortBar extends StatelessWidget {
  const StoreSortBar({
    super.key,
    required this.sort,
    required this.onChanged,
  });

  final StoreSort sort;
  final ValueChanged<StoreSort> onChanged;

  /// Deliberately compact. The first cut ran 18/10 padding at 14px inside a
  /// 60px band, which put a row of buttons the weight of primary actions above
  /// a list they only re-order — and pushed the first store card most of the
  /// way down the fold. This is chrome; it should read as a control strip.
  static const EdgeInsets _chipPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 7);
  static const double _barHeight = 50;

  @override
  Widget build(BuildContext context) {
    return Container(
      // White band, so the row reads as part of the header chrome rather than
      // as three cards floating on the tinted list behind it.
      color: AppColors.white,
      height: _barHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(
            value: StoreSort.nearest,
            icon: AppIconAssets.location_outline,
            label: 'Nearest Stores',
          ),
          const SizedBox(width: 10),
          _chip(
            value: StoreSort.rating,
            icon: AppIconAssets.star,
            label: 'Rating',
          ),
          const SizedBox(width: 10),
          _chip(
            value: StoreSort.products,
            icon: AppIconAssets.productCartIcon,
            label: 'Products',
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required StoreSort value,
    required String icon,
    required String label,
  }) {
    final selected = sort == value;
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Re-sorting is local, so no fetch here — the chip reorders what is
        // already loaded and load-more keeps appending underneath it.
        onTap: selected ? null : () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: _chipPadding,
          decoration: BoxDecoration(
            // The active chip only tints — same pill, same border weight, same
            // text size. These three are one control in three positions, and a
            // chip that changed shape when chosen would make the row jump as
            // you moved between them.
            color: selected
                ? AppColors.primaryColor.withValues(alpha: 0.08)
                : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primaryColor.withValues(alpha: 0.40)
                  : const Color(0xFFDDE3EB),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(
                imagePath: icon,
                // The star carries its own gold; recolouring it to the chip's
                // ink would strip the one glyph the user reads as a rating.
                imgColor: value == StoreSort.rating
                    ? null
                    : (selected
                        ? AppColors.primaryColor
                        : const Color(0xFF64748B)),
                height: 16,
                width: 16,
              ),
              const SizedBox(width: 7),
              CustomText(
                label,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    selected ? AppColors.primaryColor : AppColors.mainTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
