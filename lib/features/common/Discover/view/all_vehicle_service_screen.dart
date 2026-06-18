import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Public Discover-side listing for the automotive vertical.
///
/// Mirrors [AllEducationServiceScreen] visually so the Discover tabs
/// feel consistent — a banner carousel up top, a pinned horizontal
/// category bar, then an infinite-scrolling vertical list. Wiring
/// differences from the education screen:
///
///   * **Source of truth**: [VehicleController] (from
///     `lib/features/me/vehicle/`) hits `GET /vehicles` via
///     [VehicleRepo.listVehicles]. The model + repo are the *only*
///     vehicle-domain dependencies — anything UI-shaped lives here.
///   * **Categories**: `automotiveServiceItemsCategories`
///     ([CollapsibleGridModel]) — same list the home tile uses.
///   * **Category → API mapping**: not every Discover slug maps to a
///     backend `CATEGORY` enum (only `Vehicle_Sales`, `Vehicle_Rental`,
///     `Transport_Logistic` do). Unmapped slugs fall back to the
///     unfiltered listing, matching the behaviour of
///     `AutomotiveServiceCardWidget._slugToCategory`.
///   * **Tap behaviour**: opens [VehicleDetailScreen] (which itself
///     pulls `GET /vehicles/get/:id` for full owner/business
///     hydration).
class AllVehicleServiceScreen extends StatefulWidget {
  /// Full list of automotive sub-categories — passed in instead of
  /// being read from a constant so the parent can curate (or hide
  /// disabled slugs) without this screen knowing about them.
  final List<CollapsibleGridModel> automotiveCategories;

  /// Optional pre-selected category — when the user taps a specific
  /// tile on the home screen we want the listing to land already
  /// filtered to that slug.
  final CollapsibleGridModel? selectedAutomotiveData;

  const AllVehicleServiceScreen({
    super.key,
    required this.automotiveCategories,
    this.selectedAutomotiveData,
  });

  @override
  State<AllVehicleServiceScreen> createState() =>
      _AllVehicleServiceScreenState();
}

class _AllVehicleServiceScreenState extends State<AllVehicleServiceScreen> {
  /// Shared controller — `permanent: true` because the detail screen
  /// pulled in by a card tap also reuses this instance to read the
  /// already-fetched listing while the per-id call resolves.
  final VehicleController _controller =
      getOrPut(() => VehicleController(), permanent: true);

  final ScrollController _scrollController = ScrollController();
  late List<CollapsibleGridModel> _automotiveCategories;
  CollapsibleGridModel? _selected;

  /// Vehicle-themed banner imagery — Freepik stock kept consistent with
  /// the education screen's hosting choice so caching/CDN parity holds.
  final List<String> _bannerImages = const [
    'https://img.freepik.com/free-photo/red-car-with-trunk-that-says-toyota-it_1340-39044.jpg?w=1380',
    'https://img.freepik.com/free-photo/black-suv-car-front-view_114579-4153.jpg?w=1380',
    'https://img.freepik.com/free-photo/big-truck-road_181624-37941.jpg?w=1380',
  ];

  /// Slugs from `automotiveServiceItemsCategories` that *do* line up with
  /// a backend `CATEGORY` enum value — kept inline + identical to the
  /// home-tile mapping so the listing initialises with the same filter
  /// the user would expect after tapping the tile.
  static const _slugToCategory = <String, String>{
    'Vehicle_Sales': 'CAR',
    'Vehicle_Rental': 'CAR',
    'Transport_Logistic': 'TRUCK',
  };

  @override
  void initState() {
    super.initState();
    _automotiveCategories = widget.automotiveCategories;
    _selected = widget.selectedAutomotiveData;
    _fetch();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // 200px pre-trigger keeps load-more in flight before the user
        // hits the bottom — mirrors the cadence used by other Discover
        // listings.
        _controller.loadMorePublicVehicles();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Resolves the category-chip selection to the API filter and fires a
  /// first-page fetch. Called from initState and every chip tap.
  void _fetch() {
    final slug = _selected?.slugId;
    final categoryFilter = slug == null ? null : _slugToCategory[slug];
    _controller.fetchPublicVehicles(category: categoryFilter);
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      StickyCategory(
          id: 'ALL_OPTION', name: AppStrings.all.tr, imageUrl: AppImageAssets.all),
      ..._automotiveCategories.map((c) => StickyCategory(
            id: c.slugId,
            name: c.name,
            imageUrl: c.icon,
          )),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
                    statusBarHeight: statusBarHeight,
                    backgroundColor:
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                    bottomBorderSide: const BorderSide(
                      color: AppColors.white,
                      width: 2,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    categories: stickyCategories,
                    selectedId: _selected?.slugId ?? 'ALL_OPTION',
                    onCategoryTap: (item) {
                      _selected = item.id == 'ALL_OPTION'
                          ? null
                          : _automotiveCategories
                              .firstWhere((c) => c.slugId == item.id);
                      _fetch();
                      setState(() {});
                    },
                    onBack: () => Navigator.pop(context),
                    expandedLabelColor: AppColors.white,
                    backgroundGradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                        AppColors.blue5CAF.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                _buildListSliver(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSliver() {
    return Obx(() {
      final state = _controller.publicVehiclesState.value;
      final list = _controller.publicVehicles;

      // First-page loader: full sliver placeholder identical to
      // education screen so the layout doesn't jump when results land.
      if (state.status == Status.LOADING && list.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (list.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size24,
              vertical: SizeConfig.size40,
            ),
            child: _NoVehiclesFound(
              title: AppStrings.noVehiclesFound.tr,
              subtitle: AppStrings.noVehiclesFoundSubtitle.tr,
              onRetry: _fetch,
            ),
          ),
        );
      }

      // Trailing loader sliver row for the load-more path. We don't
      // surface a discrete "load more" state on the controller, so
      // approximate it: show the loader while a load is in flight *and*
      // we still expect more pages from the server.
      final showMoreLoader = state.status == Status.LOADING &&
          _controller.publicHasMore.value &&
          list.isNotEmpty;

      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size10,
        ),
        sliver: SliverList.builder(
          itemCount: list.length + (showMoreLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == list.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final Vehicle v = list[index];
            return Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size12),
              child: _DiscoverVehicleCard(
                vehicle: v,
                onTap: () {
                  final id = v.id;
                  if (id == null || id.isEmpty) return;
                  Get.to(() => VehicleDetailScreen(vehicleId: id));
                },
              ),
            );
          },
        ),
      );
    });
  }
}

/// Empty-state used when [VehicleController.publicVehicles] is empty
/// after a fetch. Visual twin of the school empty-state on the
/// education screen — single round illustration, title, subtitle and
/// an optional Retry pill.
class _NoVehiclesFound extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _NoVehiclesFound({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final illustrationSize = SizeConfig.size80;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: illustrationSize,
          height: illustrationSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.12),
                AppColors.primaryColor.withValues(alpha: 0.04),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.directions_car_rounded,
            size: illustrationSize * 0.5,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        CustomText(
          title,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size8),
        CustomText(
          subtitle,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (onRetry != null) ...[
          SizedBox(height: SizeConfig.size16),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh,
                      color: AppColors.white, size: SizeConfig.size18),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    AppStrings.retry.tr,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Discover-side listing card — a vertical, image-led card that mirrors
/// the automotive showroom reference design.
///
/// Visual anatomy (top → bottom):
///   * **Image slider** — [CustomImageSlideshow] over `vehicle.images`
///     (falls back to `cover_image`), rounded only at the top, with a
///     floating verified badge (top-left) and share / wishlist actions
///     (top-right).
///   * **Title + description** — name with an inline verified tick and a
///     two-line muted description.
///   * **Spec strip** — up to three icon+label cells (fuel, transmission,
///     mileage/seats) divided by hairlines, rendered only for the specs
///     the vehicle actually carries.
///   * **Price block** — tinted container showing the listing price.
///   * **Actions** — outlined *Chat* + filled *Book Now* buttons.
///
/// Owner-side surfaces keep using [VehicleCard]; this card is scoped to
/// the public Discover listing only.
class _DiscoverVehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  /// Opens the detail screen — also wired to the *Book Now* button.
  final VoidCallback onTap;

  const _DiscoverVehicleCard({
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> images = vehicle.images.isNotEmpty
        ? vehicle.images
        : ((vehicle.coverImage?.isNotEmpty ?? false)
            ? [vehicle.coverImage!]
            : const <String>[]);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageHeader(images),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleRow(),
                  if ((vehicle.description ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      vehicle.description!.trim(),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (_specs().isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size12),
                    _specStrip(),
                  ],
                  if (vehicle.price != null) ...[
                    SizedBox(height: SizeConfig.size12),
                    _priceBlock(),
                  ],
                  SizedBox(height: SizeConfig.size12),
                  _actions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Image header (slider + overlays) ───────────────────────────
  Widget _imageHeader(List<String> images) {
    return Stack(
      children: [
        CustomImageSlideshow(
          isLoading: false,
          imagePaths: images,
          width: double.infinity,
          height: 190,
          boxFit: BoxFit.cover,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        if (vehicle.isVerified ?? false)
          Positioned(left: 10, top: 10, child: _verifiedBadge()),
        Positioned(
          right: 10,
          top: 10,
          child: Column(
            children: [
              _circleAction(Icons.share_outlined),
              SizedBox(height: SizeConfig.size8),
              _circleAction(Icons.favorite_border_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            AppStrings.verified.tr,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }

  Widget _circleAction(IconData icon) {
    return GestureDetector(
      onTap: () => commonSnackBar(message: "Coming soon...."),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6)],
        ),
        child: Icon(icon, size: 18, color: AppColors.mainTextColor),
      ),
    );
  }

  // ─── Title ───────────────────────────────────────────────────────
  Widget _titleRow() {
    return CustomText(
      vehicle.name,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.mainTextColor,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ─── Spec strip ───────────────────────────────────────────────────
  /// Builds the (icon, label) cells backed by data the vehicle carries —
  /// capped at three so the divided row stays balanced like the design.
  List<MapEntry<IconData, String>> _specs() {
    final specs = <MapEntry<IconData, String>>[];
    if (vehicle.fuelType != null) {
      specs.add(MapEntry(
          Icons.local_gas_station_outlined, _humanFuel(vehicle.fuelType!)));
    }
    if (vehicle.transmission != null) {
      specs.add(MapEntry(
          Icons.settings_outlined, _humanTransmission(vehicle.transmission!)));
    }
    if ((vehicle.mileage ?? '').trim().isNotEmpty) {
      specs.add(MapEntry(Icons.speed_outlined, vehicle.mileage!.trim()));
    }
    if (specs.length < 3 && vehicle.seatingCapacity != null) {
      specs.add(MapEntry(
        Icons.event_seat_outlined,
        AppStrings.seatsCountFmt.trParams({'count': '${vehicle.seatingCapacity}'}),
      ));
    }
    return specs.take(3).toList();
  }

  Widget _specStrip() {
    final specs = _specs();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF4)),
      ),
      child: Row(
        children: List.generate(specs.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Container(
              width: 1,
              height: 34,
              color: const Color(0xFFE0E6EE),
            );
          }
          final spec = specs[i ~/ 2];
          return Expanded(child: _specCell(spec.key, spec.value));
        }),
      ),
    );
  }

  Widget _specCell(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryColor),
        SizedBox(height: SizeConfig.size4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: CustomText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ─── Price ─────────────────────────────────────────────────────────
  Widget _priceBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.price.tr,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size2),
          CustomText(
            _priceLabel(),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────
  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => commonSnackBar(message: "Coming soon...."),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 16, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    AppStrings.chat.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    AppStrings.bookNow.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Formatting helpers (mirror VehicleCard) ────────────────────────
  String _priceLabel() {
    final cur = (vehicle.currency ?? 'INR').toUpperCase();
    final symbol = cur == 'INR' ? '₹' : cur;
    return '$symbol ${_compactNumber(vehicle.price!)}';
  }

  String _compactNumber(double v) {
    if (v >= 1e7) {
      return '${(v / 1e7).toStringAsFixed(2)} ${AppStrings.compactUnitCr.tr}';
    }
    if (v >= 1e5) {
      return '${(v / 1e5).toStringAsFixed(2)} ${AppStrings.compactUnitLac.tr}';
    }
    if (v >= 1e3) {
      return '${(v / 1e3).toStringAsFixed(1)}${AppStrings.compactUnitThousand.tr}';
    }
    return v.toStringAsFixed(0);
  }

  String _humanFuel(VehicleFuelType f) {
    switch (f) {
      case VehicleFuelType.petrol:
        return AppStrings.fuelPetrol.tr;
      case VehicleFuelType.diesel:
        return AppStrings.fuelDiesel.tr;
      case VehicleFuelType.electric:
        return AppStrings.fuelElectric.tr;
      case VehicleFuelType.cng:
        return AppStrings.fuelCng.tr;
      case VehicleFuelType.hybrid:
        return AppStrings.fuelHybrid.tr;
      case VehicleFuelType.other:
        return AppStrings.fuelOther.tr;
    }
  }

  String _humanTransmission(VehicleTransmission t) {
    switch (t) {
      case VehicleTransmission.manual:
        return AppStrings.transmissionManual.tr;
      case VehicleTransmission.automatic:
        return AppStrings.transmissionAutomatic.tr;
      case VehicleTransmission.amt:
        return AppStrings.transmissionAmt.tr;
      case VehicleTransmission.cvt:
        return AppStrings.transmissionCvt.tr;
    }
  }
}
