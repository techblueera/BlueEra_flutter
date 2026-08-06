import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photos_viewer.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';

/// One restaurant in the near-me listing — the flat white row from
/// `assets/food_card.jpeg`.
///
/// A sibling of `GroceryStoreCard`, deliberately separate rather than one
/// shared row with a slot for the differences. They look alike today and are
/// already not the same object: this one states a veg / non-veg claim, opens
/// the food store screen rather than the grocery one, and is the likelier of
/// the two to grow menu-specific detail. Apart, neither vertical has to reason
/// about the other before changing its own list.
///
/// ## What each part does when tapped
///
///  * **The logo** opens the store's LIVE PHOTOS in a lightbox, flying the
///    avatar into the first photo with a [Hero]. Only stores that actually have
///    live photos get this, and they advertise it with the gradient ring around
///    the avatar — the same "there is something to open here" cue a story ring
///    gives. A store with no photos gets a plain avatar and falls through to the
///    store page like the rest of the row.
///  * **The distance pill** opens the directions sheet.
///  * **Everything else** opens the store.
///
/// Each store is its OWN card with a gap under it, not a row in a continuous
/// sheet: butted together with only a hairline between them the rows read as one
/// undifferentiated block, and it's the gap that makes each store scan as a
/// separate thing you can tap.
class RestaurantStoreCard extends StatelessWidget {
  const RestaurantStoreCard({super.key, required this.store});

  final GetAllStoreResModel store;

  static const Color _kSheet = Colors.white;
  static const Color _kCardBorder = AppColors.greyE5;
  static const Color _kPillBorder = Color(0xFFE3E8EF);
  static const double _kRadius = 16;

  /// The one accent on the card — distance, its pin, and the products glyph.
  /// Everything else is ink or grey, so the eye lands on "how far" and "how
  /// much", which is the whole decision being made in this list.
  static const Color _kAccent = AppColors.blue5CAF;

  /// Live photos, empty entries dropped — the backend sends `[""]` for some
  /// stores, which would otherwise light the ring up on a store with nothing
  /// behind it.
  List<String> get _livePhotos => (store.livePhotos ?? const <String>[])
      .where((p) => p.trim().isNotEmpty)
      .toList();

  /// Hero tag tying the avatar to the first photo in the lightbox. Keyed on the
  /// store id so two cards can never claim the same tag.
  String get _heroTag => 'restaurant_live_${store.id ?? store.userId ?? ''}';

  @override
  Widget build(BuildContext context) {
    final photos = _livePhotos;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: _kSheet,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // Clipped so the ink ripple stays inside the rounded corners instead of
      // painting square over them.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_kRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openStore,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14,
              vertical: SizeConfig.size14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _avatar(context, photos),
                SizedBox(width: SizeConfig.size12),
                Expanded(child: _details(context)),
                SizedBox(width: SizeConfig.size10),
                _productsPill(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo ───────────────────────────────────────────────────────────────

  /// The store logo. Ringed and tappable when there are live photos behind it,
  /// plain when there aren't.
  ///
  /// The [Hero] is only attached in the ringed case: a hero with no matching tag
  /// on the incoming route is harmless, but attaching one to a card that can't
  /// open the viewer would be a lie about what the widget does.
  Widget _avatar(BuildContext context, List<String> photos) {
    const double size = 64;
    final avatar = CachedAvatarWidget(
      imageUrl: store.logo ?? '',
      size: size,
      borderColor: Colors.white,
      borderRadius: size / 2,
      // The card owns this tap (it opens the lightbox); the avatar's own
      // full-screen viewer would fight it and show the logo instead of the
      // store's photos.
      showProfileOnFullScreen: false,
    );

    if (photos.isEmpty) return avatar;

    return GestureDetector(
      // The row underneath opens the store — this tap must not reach it.
      behavior: HitTestBehavior.opaque,
      onTap: () => StoreLivePhotosViewer.open(
        context,
        images: photos,
        heroTag: _heroTag,
        title: store.businessName ?? AppStrings.na,
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          // Story-style ring: the cue that there is something to open here.
          gradient: SweepGradient(
            colors: [
              Color(0xFF16C47F),
              Color(0xFF00A8E8),
              Color(0xFF8B5CF6),
              Color(0xFFFF7A45),
              Color(0xFFFFC53D),
              Color(0xFF16C47F),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Hero(tag: _heroTag, child: avatar),
        ),
      ),
    );
  }

  // ─── Middle column ──────────────────────────────────────────────────────

  Widget _details(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          store.businessName ?? 'Unknown Business',
          fontSize: 17,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size6),
        _ratingRow(),
        SizedBox(height: SizeConfig.size6),
        _locationRow(context),
      ],
    );
  }

  /// `★ 4.8 | General Store` — one line of plain text rather than two coloured
  /// pills.
  ///
  /// The pills were competing with the store name for the eye and with each
  /// other for the width; at this size the rating and the shop type are
  /// secondary facts, so they read as a caption and let the name lead.
  Widget _ratingRow() {
    return Row(
      children: [
        LocalAssets(imagePath: AppIconAssets.star, height: 13, width: 13),
        const SizedBox(width: 4),
        CustomText(
          '${store.avgRating ?? 0}',
          fontSize: 13,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w700,
        ),
        _divider(),
        // The veg / non-veg square sits INSIDE the rating line, immediately
        // before the category — it qualifies the cuisine ("veg — Cloud
        // Kitchen"), not the business. Hung off the store name it would read as
        // a badge the restaurant had earned.
        _vegMark(_isVeg(_subCategory)),
        const SizedBox(width: 5),
        Flexible(
          child: CustomText(
            _subCategory,
            fontSize: 13,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String get _subCategory =>
      store.subCategoryOfBusiness?.name ??
      store.categoryOfBusiness?.name ??
      AppStrings.na;

  /// Whether a cuisine name reads as vegetarian.
  ///
  /// Keyword sniffing on the category NAME, because the listing carries no veg
  /// flag. Deliberately biased toward "veg": the mark is a claim about someone's
  /// food, and of the two possible errors, labelling a veg kitchen non-veg is
  /// the one that matters to the diner who cares.
  bool _isVeg(String subCategoryName) {
    final name = subCategoryName.toLowerCase();
    return !name.contains('non') &&
        !name.contains('meat') &&
        !name.contains('chicken') &&
        !name.contains('fish');
  }

  /// The FSSAI-style square — green ring + dot for veg, red for non-veg.
  Widget _vegMark(bool isVeg, {double size = 12}) {
    final color = isVeg ? const Color(0xFF1B7F4B) : const Color(0xFFD22B2B);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  /// `📍 4.5 Km | Sastri Nagar, Lucknow…` — distance and address on one line.
  ///
  /// The whole row is the tap target for directions. Distance used to be a pill
  /// off on the right, which put the number nowhere near the address it
  /// qualifies and made the map reachable only from a chip the size of a
  /// fingernail; together they read as one fact ("how far, and where") and give
  /// the gesture a line to aim at.
  Widget _locationRow(BuildContext context) {
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      store.businessLocation?.lat?.toDouble() ?? 0.0,
      store.businessLocation?.lon?.toDouble() ?? 0.0,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMapBottomSheet(context),
      child: Row(
        children: [
          LocalAssets(
            imagePath: AppIconAssets.location_outline,
            imgColor: _kAccent,
            height: 13,
            width: 13,
          ),
          const SizedBox(width: 4),
          CustomText(
            '${km.toStringAsFixed(1)} Km',
            fontSize: 12.5,
            color: _kAccent,
            fontWeight: FontWeight.w700,
          ),
          _divider(),
          Flexible(
            child: CustomText(
              store.address ?? AppStrings.na,
              fontSize: 12.5,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w400,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Hairline between two facts on the same line.
  Widget _divider() => Container(
        width: 1,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: const Color(0xFFDDE3EB),
      );

  // ─── Right column ───────────────────────────────────────────────────────

  /// The product count, stacked in its own outlined box.
  ///
  /// Products only. The category count that used to sit beside it answered a
  /// question nobody asked of a shop they are deciding whether to open — how
  /// much is in there is the one number that separates a stocked store from an
  /// empty listing, so it gets the space to itself.
  ///
  /// [Obx] because the counts arrive on their own call after the card is on
  /// screen (see [StoreController.fetchStoreCountsFor]); the figure fills itself
  /// in when it lands instead of the list waiting on it. Until then
  /// [_formatCount] renders a dash — never a `0`, which would read as a fact
  /// about the shop rather than as "not loaded".
  Widget _productsPill() {
    return Obx(() {
      final counts = storeCountsFor(store);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPillBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.productCartIcon,
                  imgColor: _kAccent,
                  height: 12,
                  width: 12,
                ),
                const SizedBox(width: 4),
                CustomText(
                  _formatCount(counts?.productCount),
                  fontSize: 13,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
            const SizedBox(height: 1),
            CustomText(
              'Products',
              fontSize: 10,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      );
    });
  }

  // ─── Actions ────────────────────────────────────────────────────────────

  /// Opens the store's own screen.
  ///
  /// The DESTINATION is the caller's, not this card's: a grocery row leads to
  /// the grocery store screen and a restaurant row to the food one, and a card
  /// shared across verticals cannot know which. It used to hardcode the grocery
  /// route, which was invisible while grocery was the only caller and would
  /// have quietly sent every restaurant to a grocery screen the moment it
  /// wasn't.
  /// Routed through [openVisitProfile] so the type→screen mapping stays in one
  /// place. The food store screen hydrates from the business id alone, so
  /// there's nothing to hand over beyond it.
  void _openStore() {
    if (store.id == null) return;
    openVisitProfile(
      accountType: AppConstants.business,
      typeOfBusiness: BusinessType.Food.name,
      businessId: store.id,
      userId: store.userId,
    );
  }

  void _showMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.businessName ?? AppStrings.restaurant.tr,
      destinationAddress: store.address ?? '',
      destinationLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: store.livePhotos,
      // Same destination as tapping the card — the sheet's "Visit" is the
      // same action reached a different way.
      visitCallback: _openStore,
    );
  }

  /// A count for a stat, or `-` when it isn't known yet.
  ///
  /// Null is the pre-answer state, not zero: counts come from their own call
  /// after the card is on screen, and a `0` shown meanwhile reads as "this store
  /// stocks nothing" rather than "not loaded".
  static String _formatCount(int? count) {
    if (count == null) return '-';
    if (count >= 1000000) {
      final v = count / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
    }
    if (count >= 1000) {
      final v = count / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K';
    }
    return '$count';
  }
}

