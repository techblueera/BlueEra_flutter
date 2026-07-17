import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_discover_models.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/me/food/view/customer/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/visit_grocery_store_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_store_details_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single "Near You" rail. The nearby-discover response is ONE mixed set —
/// grocery/food/product stores + self-employed/professional service workers +
/// gig riders — so this rail flattens them all into one distance-sorted list of
/// circular avatars (the reference `nearest_stores.jpeg` UI) and routes each
/// item to its OWN screen based on the card's type:
///
///   store   → grocery / food / product store-visit screen
///   service → self-employee / professional provider profile
///   rider   → provider profile (fallback — no dedicated rider screen yet)
///
/// Self-managing like the recently-visited rail: own white card, collapses when
/// there's nothing nearby.
class NearestStoresSection extends StatefulWidget {
  final VoidCallback? onViewAll;

  const NearestStoresSection({super.key, this.onViewAll});

  @override
  State<NearestStoresSection> createState() => _NearestStoresSectionState();
}

class _NearestStoresSectionState extends State<NearestStoresSection> {
  final _controller = getOrPut(() => NearbyStoresController());

  static const double _railHeight = 116;

  /// Drives the refresh button's spinner. Local rather than read off the
  /// controller because the refresh also re-acquires location first, and
  /// `isLoading` only covers the network call itself.
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller.fetchIfNeeded();
  }

  /// Refresh THIS rail only — re-acquire location so a move is picked up, then
  /// force-refetch nearby-discover (bypassing the controller's 24h TTL).
  ///
  /// This replaces the old Discover header refresh, which reloaded every rail
  /// at once. Re-entrancy-guarded.
  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await LocationService.ensureUsableLocation();
      await _controller.fetch();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  /// Merge stores + services + riders into one rail.
  ///
  /// **Live workers lead**, then everything else nearest-first. The backend
  /// deliberately ranks live workers ahead of closer offline ones, and the
  /// guide is explicit: *"don't re-sort purely by distance or you'll bury the
  /// available people"* (§2.4, §7). This rail flattens several buckets into one
  /// list so it must re-sort — but only *within* that rule, never across it.
  /// Stores have no live concept and sort by distance among themselves.
  List<_NearbyEntry> _entries() {
    final list = <_NearbyEntry>[
      ..._controller.stores.map(_NearbyEntry.store),
      ..._controller.services.map(_NearbyEntry.worker),
      ..._controller.riders.map(_NearbyEntry.worker),
    ]..sort((a, b) {
        if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
        return a.distance.compareTo(b.distance);
      });
    return list;
  }

  void _open(_NearbyEntry e) {
    final store = e.store;
    if (store != null) {
      switch (store.type.toLowerCase()) {
        case 'food':
          Get.to(() => VisitFoodStoreDetailsScreen(visitBusinessId: store.id));
          break;
        case 'product':
          Get.to(() =>
              VisitProductStoreDetailsScreen(visitUserId: store.userId ?? ''));
          break;
        case 'grocery':
        default:
          Get.to(() => VisitGroceryStoreScreen(
                visitBusinessId: store.id,
                userId: store.userId ?? '',
              ));
      }
      return;
    }
    final worker = e.worker!;
    if (worker.userId.isEmpty) return;
    // Professional → consultant view; self-employed AND riders → the
    // self-employee view by userId (rider has no dedicated profile screen yet).
    if (worker.isProfessional) {
      Get.to(() => DiscoverProfessionalsViewScreen(userId: worker.userId));
    } else {
      Get.to(() => SelfEmployeeViewDiscoverScreen(userId: worker.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = _entries();
      // Shimmer on the first load AND on a button refresh, so a refresh reads
      // as a reload rather than a frozen rail. `fetch()` leaves the old list in
      // place until the new one lands (it only `assignAll`s on success), so
      // `entries` stays non-empty mid-refresh — hence the explicit
      // `_isRefreshing`, which also covers the location fix before the call.
      //
      // Pull-to-refresh deliberately doesn't shimmer: RefreshIndicator has its
      // own spinner and keeping the content is the expected behaviour there.
      final loading =
          _isRefreshing || (_controller.isLoading.value && entries.isEmpty);

      if (_controller.loaded.value && !loading && entries.isEmpty) {
        // Guide §4: an empty slice whose label is in `meta.degraded` means an
        // OUTAGE, not "nothing nearby" — the response is still 200. Collapsing
        // silently tells the user there's nothing around them and leaves them
        // no way to recover, so offer a retry instead.
        if (_controller.degraded.value) return _degradedCard();
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      'Nearest Stores',
                      fontSize: SizeConfig.large18,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _refreshButton(),
                  SizedBox(width: SizeConfig.size8),
                  if (widget.onViewAll != null)
                    ViewAllButton(onTap: widget.onViewAll!),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            SizedBox(
              height: _railHeight,
              child: loading
                  ? _loadingRow()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: SizeConfig.size16),
                      itemBuilder: (context, index) =>
                          _NearbyAvatar(entry: entries[index], onTap: _open),
                    ),
            ),
          ],
        ),
      );
    });
  }

  /// Refresh affordance sitting left of "View All" — refreshes only this rail.
  ///
  /// Wears the same pale-blue chip as [ViewAllButton] (`primaryColor.withAlpha(10)`,
  /// radius 30) so the two read as a matched pair rather than a stray icon.
  /// Spins while running, and is inert both while refreshing and while the
  /// controller's own fetch is in flight, so it can't stack requests.
  Widget _refreshButton() {
    final busy = _isRefreshing || _controller.isLoading.value;
    return GestureDetector(
      onTap: busy ? null : _refresh,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withAlpha(10),
          borderRadius: BorderRadius.circular(30),
        ),
        child: SizedBox(
          // Fixed box so swapping icon ⇄ spinner doesn't jiggle the row.
          width: 18,
          height: 18,
          child: busy
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
        ),
      ),
    );
  }

  /// Shown when the rail is empty *because an upstream failed* — same white
  /// card as the rail so the section keeps its place, with a retry that
  /// force-refetches. Never shown for a genuinely empty area (that collapses).
  Widget _degradedCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded,
              size: SizeConfig.size20, color: AppColors.secondaryTextColor),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(
              "Couldn't load what's near you",
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          _refreshButton(),
        ],
      ),
    );
  }

  Widget _loadingRow() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size16),
      itemBuilder: (_, __) => _shimmerAvatar(),
    );
  }

  Widget _shimmerAvatar() {
    return buildLoadingShimmer(
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            shimmerContainer(width: 64, height: 64, radius: 32),
            const SizedBox(height: 10),
            // Short category bar first, then the wider name bar — same order
            // the real card lays out, so the swap to content doesn't jump.
            shimmerContainer(width: 40, height: 9, radius: 4),
            const SizedBox(height: 6),
            shimmerContainer(width: 56, height: 11, radius: 4),
          ],
        ),
      ),
    );
  }
}

/// A merged nearby item — either a store or a worker.
class _NearbyEntry {
  final NearbyStoreCard? store;
  final NearbyWorkerCard? worker;

  const _NearbyEntry.store(this.store) : worker = null;
  const _NearbyEntry.worker(this.worker) : store = null;

  double get distance => store?.distance ?? worker?.distance ?? 0;

  /// Only workers can be live — a store is never "live" in this sense, so it
  /// sorts purely on distance.
  bool get isLive => worker?.live ?? false;
}

class _NearbyAvatar extends StatelessWidget {
  final _NearbyEntry entry;
  final void Function(_NearbyEntry entry) onTap;

  const _NearbyAvatar({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = entry.store;
    final worker = entry.worker;

    // Stores: own logo first, then the category image. Workers: profile image.
    final String image =
        store != null ? store.displayImage : (worker?.profileImage ?? '');
    final String name = store != null
        ? store.businessName
        : (worker!.name.isNotEmpty ? worker.name : worker.professionName);
    final String label =
        store != null ? store.displayCategory : (worker?.displayLabel ?? '');
    final bool live = worker?.live ?? false;
    // Stores get the navy "storefront" circle; workers get a person circle.
    final bool isStore = store != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(entry),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isStore
                        ? const Color(0xFF17233F)
                        : AppColors.primaryColor.withValues(alpha: 0.10),
                    // Slight hairline border + soft shadow so the logo lifts off
                    // the white card.
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14101828),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _fallbackIcon(isStore),
                          errorWidget: (_, __, ___) => _fallbackIcon(isStore),
                        )
                      : _fallbackIcon(isStore),
                ),
                if (live)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Category reads as a small eyebrow ABOVE the name — two points
            // down from the name so the name still wins the row, and the pair
            // reads as one block rather than two competing labels.

              CustomText(
                name,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 2),
            if (label.isNotEmpty)
            CustomText(
              label,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(bool isStore) => Center(
        child: Icon(
          isStore ? Icons.storefront_rounded : Icons.person,
          color: isStore ? Colors.white : AppColors.primaryColor,
          size: isStore ? 26 : 30,
        ),
      );
}
