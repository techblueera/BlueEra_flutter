import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_card.dart';
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
              padding: EdgeInsets.only(bottom: SizeConfig.size10),
              child: VehicleCard(
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
