import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_discover_models.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/quick_rider_book_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_glass.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
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

  /// Height of one item plate: a horizontal [ListView] constrains its children
  /// tightly on the cross axis, so this IS the plate height and every plate is
  /// identical.
  ///
  /// Measured against the content rather than rounded up: avatar (66) + the
  /// chip's 9px overhang + 6 gap + the two label lines (~30 at these sizes) +
  /// the plate's 16 of vertical padding ≈ 127. The 4px over that is headroom for
  /// scripts whose line boxes run taller than Latin's, and the item centres
  /// itself in whatever is left so the slack never collects under the last line.
  ///
  /// The plate's own parts are fixed pixels rather than [SizeConfig] steps for
  /// the same reason the folder tile's are: this rail has to line up with that
  /// grid, and the grid's geometry is fixed.
  static const double _railHeight = 131;

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
      // `type` (Grocery | Food | Product) is the BUCKET the backend put this
      // store in, not `typeOfBusiness` — a Service business that lists products
      // arrives here as `type: Product, typeOfBusiness: Service`, and the
      // product store is what the user wants. So route on the bucket, exactly
      // as this rail always has.
      openVisitProfile(
        accountType: AppConstants.business,
        typeOfBusiness: store.type,
        categoryOfBusiness: store.categoryName,
        businessId: store.id,
        userId: store.userId,
      );
      return;
    }
    final worker = e.worker!;
    if (worker.userId.isEmpty) return;
    // Riders (gig workers) → the quick-book flow instead of a profile: the user
    // wants to hire THIS rider, not view them. Enter drop location on a map and
    // connect to the rider. Deliberately NOT routed through openVisitProfile —
    // that opens profiles, and this is a booking.
    if (worker.isRider) {
      Get.to(() => QuickRiderBookScreen(rider: worker));
      return;
    }
    // `profession` is the coarse SELF_EMPLOYED / PROFESSIONAL enum the guide
    // says to route on (`profileType` is the display string "Self Employed" /
    // "GigWork"), so that's what the resolver gets.
    openVisitProfile(
      accountType: AppConstants.individual,
      profileType: worker.profession,
      userId: worker.userId,
    );
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

      // The panel is the shared Discover glass — same fill, blur, rim, lift and
      // 26px radius as the folder tiles below it, so the rail sits in the same
      // material as the rest of the page instead of on a white sheet laid over
      // it. It inherits the grid's own 14px side inset from
      // `_buildSectionsColumn`, so the edges line up with the folders too.
      return Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.size14),
        child: DiscoverGlassPanel(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        AppStrings.nearestStores.tr,
                        fontSize: SizeConfig.large18,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _refreshButton(),
                    SizedBox(width: SizeConfig.size8),
                    if (widget.onViewAll != null)
                      // Raw key: CustomText `.tr`s its own title.
                      _GlassChip(
                        onTap: widget.onViewAll!,
                        label: AppStrings.viewAll,
                      ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size12),
              SizedBox(
                height: _railHeight,
                child: loading
                    ? _loadingRow()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size14),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: _kItemGap),
                        itemBuilder: (context, index) =>
                            _NearbyAvatar(entry: entries[index], onTap: _open),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Refresh affordance sitting left of "View All" — refreshes only this rail.
  ///
  /// Wears the same white plate as [_GlassChip] so the two read as a matched
  /// pair of controls ON the glass. Its old fill was `primaryColor.withAlpha(10)`
  /// — 4% ink, which was already close to invisible on the white card and would
  /// have disappeared outright on the panel.
  ///
  /// Spins while running, and is inert both while refreshing and while the
  /// controller's own fetch is in flight, so it can't stack requests.
  Widget _refreshButton() {
    final busy = _isRefreshing || _controller.isLoading.value;
    return _GlassChip(
      onTap: busy ? null : _refresh,
      // Fixed box so swapping icon ⇄ spinner doesn't jiggle the row.
      child: SizedBox(
        width: 16,
        height: 16,
        child: busy
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor,
              )
            : const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: AppColors.primaryColor,
              ),
      ),
    );
  }

  /// Shown when the rail is empty *because an upstream failed* — the same glass
  /// panel as the rail so the section keeps both its place and its material,
  /// with a retry that force-refetches. Never shown for a genuinely empty area
  /// (that collapses).
  Widget _degradedCard() {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size14),
      child: DiscoverGlassPanel(
        padding: EdgeInsets.all(SizeConfig.size14),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded,
                size: SizeConfig.size20, color: AppColors.mainTextColor),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CustomText(
                "Couldn't load what's near you",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            _refreshButton(),
          ],
        ),
      ),
    );
  }

  Widget _loadingRow() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(width: _kItemGap),
      itemBuilder: (_, __) => _shimmerAvatar(),
    );
  }

  /// Placeholder in the shape of the real plate, so the swap to content moves
  /// nothing: same plate, same radius, same avatar circle, same two text lines.
  Widget _shimmerAvatar() {
    return _NearbyPlate(
      child: buildLoadingShimmer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            shimmerContainer(
                width: _kAvatarSize,
                height: _kAvatarSize,
                radius: _kAvatarSize / 2),
            // 9 for the chip's overhang + the 6 gap, so the bars land where the
            // real labels do.
            const SizedBox(height: 15),
            shimmerContainer(width: 54, height: 11, radius: 4),
            const SizedBox(height: 4),
            shimmerContainer(width: 34, height: 8, radius: 4),
          ],
        ),
      ),
    );
  }
}

/// Geometry of one rail item. Fixed pixels, like the folder tile's — see
/// [_NearestStoresSectionState._railHeight].
///
/// The avatar is the item: it is what gets recognised and what gets tapped, so
/// it takes nearly the plate's full width and the labels read as its caption.
const double _kItemWidth = 82;
const double _kItemGap = 10;
const double _kAvatarSize = 66;

/// Radius of an item plate. Sits between the folder tile's 26 and its inner
/// icon slots' 14: this plate holds one item, where a tile holds four.
const double _kPlateRadius = 18;

/// Availability green — the same one the recent-orders rail tags a new order
/// with, so "live/new" is one colour across the page rather than two greens a
/// shade apart.
const Color _kLiveGreen = Color(0xFF1FB35A);

/// A control sitting on the glass panel: a white plate with a hairline rim.
///
/// The page's shared [kDiscoverGlassPlateFill] is what makes a block on the
/// panel legible — the panel itself is ink over an unknown background and can't
/// be relied on for contrast, a plate can. Same reasoning as the folder tiles'
/// icon slots, and the same fill.
class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.onTap, this.label, this.child});

  /// Null disables the chip — it dims rather than disappearing, so the row
  /// doesn't reflow while a refresh is in flight.
  final VoidCallback? onTap;
  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: Material(
        color: kDiscoverGlassPlateFill,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: label != null ? 12 : 7,
              vertical: label != null ? 5 : 7,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: child ??
                CustomText(
                  label!,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

/// The white plate one rail item sits on.
///
/// This is the move that makes the rail belong to the page: the folder tiles
/// are glass panels holding bright plates, and so is this. It also carries the
/// contrast — the item's name and category are ordinary dark text, which the
/// panel alone could not guarantee on a user-chosen background.
class _NearbyPlate extends StatelessWidget {
  const _NearbyPlate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kItemWidth,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: kDiscoverGlassPlateFill,
        borderRadius: BorderRadius.circular(_kPlateRadius),
        // Fill + rim only, no lift. The folder tiles' icon slots carry no
        // shadow either — the panel underneath is what these plates lift off,
        // and five shadowed plates in a row turned the rail busy.
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: child,
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
      child: _NearbyPlate(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Centred, not top-aligned. The plate is stretched to the rail's
          // height, so whatever the content doesn't use has to go somewhere —
          // top-aligned it all collected under the category line as a band of
          // dead space. Split in two it reads as the plate's own padding.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The avatar and the two badges that qualify it. The stack is 9px
            // taller than the circle so the distance chip can ride the bottom
            // edge without being clipped.
            SizedBox(
              height: _kAvatarSize + 9,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // The rim is painted as a FOREGROUND decoration over the
                  // image, not as a border around it. A `Container` with a
                  // border insets its child by the border's width
                  // (`BoxDecoration.padding` comes from the border's
                  // dimensions), which left a dead ring inside the circle and
                  // stopped the photo ever reaching the edge. Painting the ring
                  // on top instead lets the image fill the whole circle.
                  DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      // Hairline rim in the panel's own white, so the circle
                      // separates from the plate the same way every other block
                      // on this page separates from what it sits on.
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        width: _kAvatarSize,
                        height: _kAvatarSize,
                        color: isStore
                            ? const Color(0xFF17233F)
                            : AppColors.primaryColor.withValues(alpha: 0.10),
                        child: image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: Uri.encodeFull(image),
                                fit: BoxFit.cover,
                                // Fills the circle even when the source is
                                // smaller than the box — without these the
                                // image is drawn at its intrinsic size and
                                // floats in the middle.
                                width: _kAvatarSize,
                                height: _kAvatarSize,
                                placeholder: (_, __) => _fallbackIcon(isStore),
                                errorWidget: (_, __, ___) =>
                                    _fallbackIcon(isStore),
                              )
                            : _fallbackIcon(isStore),
                      ),
                    ),
                  ),
                  // Availability, top-right: a worker who is online right now.
                  // Kept as a dot rather than folded into the chip below so the
                  // two facts stay separable — the rail sorts live-first, THEN
                  // nearest, and the badges say so in that order.
                  if (live)
                    Positioned(
                      // On the circle's upper-right edge (its 45° point), not
                      // floating in the corner beside it — the Stack is exactly
                      // as wide as the avatar, so these offsets are measured
                      // from the circle itself.
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: _kLiveGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                      ),
                    ),
                  // Distance, riding the circle's lower edge. This is the one
                  // fact that justifies the rail existing and the thing it is
                  // ordered by, so it is on the item rather than left implicit.
                  if (_distanceLabel != null)
                    Positioned(
                      bottom: 0,
                      child: _DistanceChip(label: _distanceLabel!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Both labels are [Flexible] on purpose. The rail is a fixed height
            // and the plate is stretched to it, but a line box is taller in
            // Devanagari than in Latin at the same point size — and the app ships
            // 20-odd languages. Flexible lets the text be compressed to what is
            // left rather than overflowing the plate in some locales.
            Flexible(
              child: CustomText(
                name,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 2),
              Flexible(
                child: CustomText(
                  label,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// `0.4 km` up close, `12 km` further out — a decimal is meaningful when you
  /// might walk it and noise when you won't. Null when the backend sent no
  /// distance, and the chip is then simply not drawn rather than reading `0 km`.
  ///
  /// `kmLabel` ("km") rather than `kmAway` ("km away"): the chip is 78px wide at
  /// most and the longer phrase would spill out of the plate. Sitting on the
  /// avatar is what says "away".
  String? get _distanceLabel {
    final km = entry.distance;
    if (km <= 0) return null;
    final value = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return '$value ${AppStrings.kmLabel.tr}';
  }

  Widget _fallbackIcon(bool isStore) => Center(
        child: Icon(
          isStore ? Icons.storefront_rounded : Icons.person,
          color: isStore ? Colors.white : AppColors.primaryColor,
          size: isStore ? 30 : 34,
        ),
      );
}

/// How far away this one is — the rail's ranking, made visible.
///
/// Opaque white rather than the plate's translucent fill: it overlaps the
/// avatar, and a translucent chip over a photo is unreadable.
class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Never wider than the plate it sits on: the chip is in a Stack, which
      // does not constrain it, and a long value would otherwise hang over the
      // plate's edge.
      constraints: const BoxConstraints(maxWidth: _kItemWidth - 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: CustomText(
        label,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
