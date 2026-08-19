import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_discover_models.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/quick_rider_book_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_glass.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One nearby item, its ordering rule, its avatar plate and its tap routing —
/// everything the "Near You" rail and the "Near You · View All" screen have to
/// agree on.
///
/// It lives in its own file because those two surfaces render the SAME set from
/// the SAME controller: an item that opens a store profile in the rail and a
/// grocery listing on the full screen would be two different products. Anything
/// per-surface (the rail's header and shimmer, the screen's paging) stays with
/// the surface.

/// Geometry of one rail item. Fixed pixels, like the folder tile's — see
/// the rail height in nearest_stores_section.dart.
///
/// The avatar is the item: it is what gets recognised and what gets tapped, so
/// it takes nearly the plate's full width and the labels read as its caption.
const double kNearbyItemWidth = 82;
const double kNearbyItemGap = 10;
const double kNearbyAvatarSize = 66;

/// Radius of an item plate. Sits between the folder tile's 26 and its inner
/// icon slots' 14: this plate holds one item, where a tile holds four.
const double _kPlateRadius = 18;

/// Availability green — the same one the recent-orders rail tags a new order
/// with, so "live/new" is one colour across the page rather than two greens a
/// shade apart.
const Color _kLiveGreen = Color(0xFF1FB35A);

/// The white plate one rail item sits on.
///
/// This is the move that makes the rail belong to the page: the folder tiles
/// are glass panels holding bright plates, and so is this. It also carries the
/// contrast — the item's name and category are ordinary dark text, which the
/// panel alone could not guarantee on a user-chosen background.
class NearbyPlate extends StatelessWidget {
  const NearbyPlate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kNearbyItemWidth,
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
class NearbyEntry {
  final NearbyStoreCard? store;
  final NearbyWorkerCard? worker;

  const NearbyEntry.store(this.store) : worker = null;
  const NearbyEntry.worker(this.worker) : store = null;

  double get distance => store?.distance ?? worker?.distance ?? 0;

  /// Only workers can be live — a store is never "live" in this sense, so it
  /// sorts purely on distance.
  bool get isLive => worker?.live ?? false;

  /// Stable identity, so a list that grows a page at a time can key its items
  /// and a refresh returning the same item does not rebuild it from scratch.
  String get itemKey =>
      store != null ? "store:${store!.id}" : "worker:${worker!.userId}";
}

class NearbyAvatar extends StatelessWidget {
  final NearbyEntry entry;
  final void Function(NearbyEntry entry) onTap;

  const NearbyAvatar({super.key, required this.entry, required this.onTap});

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
      child: NearbyPlate(
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
              height: kNearbyAvatarSize + 9,
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
                        width: kNearbyAvatarSize,
                        height: kNearbyAvatarSize,
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
                                width: kNearbyAvatarSize,
                                height: kNearbyAvatarSize,
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

  /// Number and unit run together — the chip is 70px wide at most, so it takes
  /// the compact form. Sitting on the avatar is what says "away". Null when the
  /// backend sent no distance, and the chip is then simply not drawn.
  String? get _distanceLabel => NearbyDistance.of(entry.distance)?.flat;

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
      constraints: const BoxConstraints(maxWidth: kNearbyItemWidth - 12),
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

/// Merge stores + services + riders into one list.
///
/// **Live workers lead**, then everything else nearest-first. The backend
/// deliberately ranks live workers ahead of closer offline ones, and the guide
/// is explicit: *"don't re-sort purely by distance or you'll bury the available
/// people"* (2.4, 7). This flattens several buckets into one list so it must
/// re-sort — but only *within* that rule, never across it. Stores have no live
/// concept and sort by distance among themselves.
List<NearbyEntry> buildNearbyEntries(NearbyStoresController controller) {
  return <NearbyEntry>[
    ...controller.stores.map(NearbyEntry.store),
    ...controller.services.map(NearbyEntry.worker),
    ...controller.riders.map(NearbyEntry.worker),
  ]..sort((a, b) {
      if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
      return a.distance.compareTo(b.distance);
    });
}

/// How far away one item is, split into the number and its unit so a caller can
/// set them at different sizes (the list's distance spine) or run them together
/// (the rail's chip, via [flat]).
///
/// Metres under a kilometre — "450 m" is a walk and "0.5 km" is a rounding —
/// one decimal up to 10 km, whole kilometres beyond it, where a decimal is
/// noise. A distance of exactly 0 is the backend saying "same coordinates as
/// you", so it reads as a word, not as "0 km".
class NearbyDistance {
  const NearbyDistance(this.value, this.unit);

  final String value;
  final String? unit;

  String get flat => unit == null ? value : '$value $unit';

  static NearbyDistance? of(double km) {
    if (km < 0) return null;
    if (km == 0) return const NearbyDistance('Here', null);
    if (km < 1) return NearbyDistance('${(km * 1000).round()}', 'm');
    if (km < 10) return NearbyDistance(km.toStringAsFixed(1), 'km');
    return NearbyDistance('${km.round()}', 'km');
  }
}

/// Route one nearby item to its OWN screen based on the card's type:
///
///   store   -> grocery / food / product store-visit screen
///   service -> self-employee / professional provider profile
///   rider   -> the quick-book flow
void openNearbyEntry(NearbyEntry e) {
  final store = e.store;
  if (store != null) {
    // The store's own bucket (Grocery | Food | Product) is what routes it, NOT
    // type_of_business — a Service business that lists products arrives here as
    // type: Product / type_of_business: Service, and the product store is what
    // the user wants. So route on the bucket, exactly as the rail always has.
    openVisitProfile(
      accountType: AppConstants.business,
      typeOfBusiness: store.type,
      categoryOfBusiness: _categoryTag(store.categoryName),
      businessId: store.id,
      userId: store.userId,
    );
    return;
  }
  final worker = e.worker!;
  if (worker.userId.isEmpty) return;
  // Riders (gig workers) -> the quick-book flow instead of a profile: the user
  // wants to hire THIS rider, not view them. Enter drop location on a map and
  // connect to the rider. Deliberately NOT routed through openVisitProfile —
  // that opens profiles, and this is a booking.
  if (worker.isRider) {
    Get.to(() => QuickRiderBookScreen(rider: worker));
    return;
  }
  // profession is the coarse SELF_EMPLOYED / PROFESSIONAL enum the guide says
  // to route on (profileType is the display string "Self Employed" /
  // "GigWork"), so that's what the resolver gets.
  openVisitProfile(
    accountType: AppConstants.individual,
    profileType: worker.profession,
    userId: worker.userId,
  );
}

/// Best-effort category *tag* from the display name the bucket carries.
///
/// `nearby/discover` sends `category: {id, name, image_url, type}` — a display
/// name ("Pharmacy"), never the `PHARMACY`-style tag [openVisitProfile] splits
/// Healthcare on. Grocery/Food/Product ignore the category entirely, so this
/// only matters for Healthcare, where it decides pharmacy vs lab vs hospital.
///
/// Uppercase + non-alphanumerics to underscores is the same shape the tags are
/// written in, so the common names line up ("Alternative Health" →
/// `ALTERNATIVE_HEALTH`). A name that doesn't match any tag falls through to
/// the generic business profile rather than dead-ending — see the routing table
/// on [openVisitProfile]. Send the real tag id in the payload and this can go.
String _categoryTag(String name) => name
    .trim()
    .toUpperCase()
    .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');
