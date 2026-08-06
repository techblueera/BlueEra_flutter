import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';

/// One store in a near-me listing — the flat white row from
/// `assets/grocery_card.jpeg` / `assets/food_card.jpeg`.
///
/// Shared by every vertical that lists shops (grocery, restaurants, …) rather
/// than copied per module: the row is the same object everywhere, and the two
/// that existed had already drifted apart on rating colour, distance precision
/// and footer copy while claiming to be the same design.
///
/// A vertical adds its own qualifier through [categoryLeading] — the veg /
/// non-veg mark on a restaurant, for instance — instead of forking the card.
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
class StoreListCard extends StatelessWidget {
  const StoreListCard({super.key, required this.store, this.categoryLeading});

  final GetAllStoreResModel store;

  /// Optional mark shown immediately before the category name on the rating
  /// line — the food listing puts its veg / non-veg square here.
  ///
  /// It sits INSIDE the rating row rather than beside the store name because it
  /// qualifies the category ("veg — Cloud Kitchen"), not the shop; hung off the
  /// title it would read as a badge the business had earned.
  final Widget? categoryLeading;

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
  String get _heroTag => 'store_live_${store.id ?? store.userId ?? ''}';

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
        if (categoryLeading != null) ...[
          categoryLeading!,
          const SizedBox(width: 5),
        ],
        Flexible(
          child: CustomText(
            store.subCategoryOfBusiness?.name ??
                store.categoryOfBusiness?.name ??
                AppStrings.na,
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

  void _openStore() {
    Get.toNamed(
      RouteHelper.getVisitGroceryStoreScreenRoute(),
      arguments: {
        ApiKeys.userId: store.userId,
        ApiKeys.businessId: store.id,
      },
    );
  }

  void _showMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.businessName ?? 'Store',
      destinationAddress: store.address ?? '',
      destinationLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: store.livePhotos,
      visitCallback: () => Get.toNamed(
        RouteHelper.getVisitGroceryStoreScreenRoute(),
        arguments: {
          ApiKeys.userId: store.userId ?? "",
          ApiKeys.businessId: store.id ?? "",
        },
      ),
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

/// Live-photo lightbox, opened from a store's logo.
///
/// ## Why this is a [PageRoute] and not a bottom sheet
///
/// It used to be a `showModalBottomSheet`, and the [Hero] on the avatar could
/// never have animated into it: Flutter's `HeroController` only runs a flight
/// when BOTH the outgoing and incoming routes are `PageRoute`s, and a modal
/// sheet is a `PopupRoute`. A [PageRouteBuilder] with `opaque: false` gives the
/// same floating-over-the-list look while being a real PageRoute, so the logo
/// actually flies into the first photo.
class StoreLivePhotosViewer extends StatefulWidget {
  const StoreLivePhotosViewer({
    super.key,
    required this.images,
    required this.heroTag,
    required this.title,
    this.initialIndex = 0,
  });

  final List<String> images;

  /// Shared with the avatar that opened this. Only the page at [initialIndex]
  /// carries it — a PageView keeps neighbouring pages alive, and two live
  /// widgets sharing one tag is a Hero assertion, not a nicer animation.
  final String heroTag;
  final String title;
  final int initialIndex;

  /// Pushes the viewer. No-op when there is nothing to show, so callers don't
  /// each have to guard.
  static void open(
    BuildContext context, {
    required List<String> images,
    required String heroTag,
    required String title,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => StoreLivePhotosViewer(
          images: images,
          heroTag: heroTag,
          title: title,
          initialIndex: initialIndex,
        ),
        // The chrome fades; the photo itself arrives on the Hero flight, so
        // sliding the page as well would drag the image away from it.
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<StoreLivePhotosViewer> createState() =>
      _StoreLivePhotosViewerState();
}

class _StoreLivePhotosViewerState extends State<StoreLivePhotosViewer> {
  late final PageController _controller;
  late int _index;
  final Map<int, TransformationController> _transformers = {};
  TapDownDetails? _lastDoubleTap;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final t in _transformers.values) {
      t.dispose();
    }
    super.dispose();
  }

  TransformationController _transformerFor(int i) =>
      _transformers.putIfAbsent(i, TransformationController.new);

  void _toggleZoom(int i) {
    final t = _transformerFor(i);
    final details = _lastDoubleTap;
    if (t.value != Matrix4.identity()) {
      t.value = Matrix4.identity();
    } else if (details != null) {
      const scale = 2.5;
      final pos = details.localPosition;
      t.value = Matrix4.identity()
        ..translate(-pos.dx * (scale - 1), -pos.dy * (scale - 1))
        ..scale(scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent over the route barrier, so the list stays faintly visible
      // behind the photos and the lightbox reads as floating on it.
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _pages()),
            _dots(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              widget.title,
              fontSize: SizeConfig.medium,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: CustomText(
              '${_index + 1} / ${widget.images.length}',
              fontSize: SizeConfig.small,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pages() {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.images.length,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (_, i) {
        final image = ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: widget.images[i],
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.contain,
            ),
          ),
        );

        return GestureDetector(
          onDoubleTapDown: (d) => _lastDoubleTap = d,
          onDoubleTap: () => _toggleZoom(i),
          child: InteractiveViewer(
            transformationController: _transformerFor(i),
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                // Only the page the avatar flew into carries the tag — see the
                // note on [StoreLivePhotosViewer.heroTag].
                child: i == widget.initialIndex
                    ? Hero(tag: widget.heroTag, child: image)
                    : image,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dots() {
    if (widget.images.length < 2) return SizedBox(height: SizeConfig.size20);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.images.length, (i) {
          final active = i == _index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryColor
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}
