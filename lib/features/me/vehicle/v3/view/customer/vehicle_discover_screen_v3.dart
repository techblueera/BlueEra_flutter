import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_buyer_controller_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/customer/vehicle_trim_listings_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/widgets/vehicle_trim_card_v3.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Buyer entry point for vehicles — what a Discover "New/Old Vehicle Sales"
/// tile now opens.
///
/// Structurally the grocery stores screen: banner carousel, a pinned category
/// strip, then an infinite list. What it lists is different, and that comes
/// straight from §6 of the integration guide — `/products/user/search` starts
/// from **live listings** and rolls them up into trim cards carrying
/// `listingCount` and `priceFrom`. So the buyer browses "Swift VXi — from
/// ₹5.2L, 4 available near you", not a wall of individual listings, and every
/// card is guaranteed to have stock behind it.
///
/// It replaces the old `VehicleListingScreen`, which read the removed
/// `/vehicles` API.
class VehicleDiscoverScreenV3 extends StatefulWidget {
  /// NEW / USED, from the tile the buyer tapped — the Discover automotive
  /// card splits one catalog category into a new and an old tile, and this is
  /// how that choice survives the jump. Null browses both.
  final String? initialCondition;

  const VehicleDiscoverScreenV3({super.key, this.initialCondition});

  @override
  State<VehicleDiscoverScreenV3> createState() =>
      _VehicleDiscoverScreenV3State();
}

class _VehicleDiscoverScreenV3State extends State<VehicleDiscoverScreenV3> {
  final VehicleBuyerControllerV3 _controller =
      getOrPut(() => VehicleBuyerControllerV3());
  final ScrollController _scrollController = ScrollController();

  /// Sentinel for the leading "All" tab — clears the category filter.
  static const String _allTypesId = 'ALL_VEHICLE_TYPES';

  final List<String> _bannerImages = const [
    'https://img.freepik.com/free-photo/red-car-with-trunk-that-says-toyota-it_1340-39044.jpg?w=1380',
    'https://img.freepik.com/free-photo/black-suv-car-front-view_114579-4153.jpg?w=1380',
    'https://img.freepik.com/free-photo/big-truck-road_181624-37941.jpg?w=1380',
  ];

  @override
  void initState() {
    super.initState();
    _controller.conditionFilter.value = widget.initialCondition;
    // Re-entry doesn't refetch unless the filters or the user's location
    // moved — same discipline as the grocery stores screen.
    _controller.loadDiscoverIfNeeded();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMoreTrims();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _title {
    final condition = _controller.conditionFilter.value;
    if (condition == VehicleListingCondition.isNew) return 'New vehicles';
    if (condition == VehicleListingCondition.used) return 'Used vehicles';
    return 'Vehicles';
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: BannerCarousel(
                images: _bannerImages,
                onBack: () => Get.back(),
                statusBarHeight: statusBarHeight,
                backgroundColor: AppColors.blue5CAF.withValues(alpha: 0.1),
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
                categories: _stickyCategories(),
                selectedId:
                    _controller.selectedCategoryId.value ?? _allTypesId,
                onCategoryTap: (item) {
                  _controller.selectCategory(
                      item.id == _allTypesId ? null : item.id);
                  setState(() {});
                },
                onBack: () => Get.back(),
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
          ],
          body: Column(
            children: [
              _conditionStrip(),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  /// Root types that actually have stock — `/categories/nested/with-inventory`
  /// is pruned server-side, so a tab here can never lead to an empty list.
  List<StickyCategory> _stickyCategories() {
    return [
      StickyCategory(id: _allTypesId, name: 'All'),
      ..._controller.categories.map(
        (c) => StickyCategory(
          id: c.id,
          name: c.name,
          imageUrl: c.image.isEmpty ? null : c.image,
        ),
      ),
    ];
  }

  /// New / used / both. The Discover tile pre-selects one, and this is where
  /// a buyer can widen or flip it without going back.
  Widget _conditionStrip() {
    return Obx(() {
      final selected = _controller.conditionFilter.value;
      return Container(
        color: AppColors.white,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size8,
        ),
        child: Row(
          children: [
            _conditionChip('All', null, selected),
            SizedBox(width: SizeConfig.size8),
            _conditionChip('New', VehicleListingCondition.isNew, selected),
            SizedBox(width: SizeConfig.size8),
            _conditionChip('Used', VehicleListingCondition.used, selected),
            const Spacer(),
            CustomText(
              _title,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      );
    });
  }

  Widget _conditionChip(String label, String? value, String? selected) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () => _controller.selectCondition(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
          ),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: isSelected
              ? AppColors.primaryColor
              : AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _body() {
    return Obx(() {
      if (_controller.locationMissing.value) return _locationPrompt();

      final loading = _controller.trimsStatus.value == Status.LOADING ||
          _controller.trimsStatus.value == Status.INITIAL;
      final trims = _controller.trims;

      if (loading && trims.isEmpty) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (trims.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message: 'No vehicles listed near you yet.',
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _controller.loadDiscover,
        child: ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size12,
            SizeConfig.size10,
            SizeConfig.size12,
            SizeConfig.size24,
          ),
          itemCount: trims.length + (_controller.isLoadingMore.value ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
          itemBuilder: (_, i) {
            if (i >= trims.length) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return VehicleTrimCardV3(
              trim: trims[i],
              onTap: () => Get.to(
                () => VehicleTrimListingsScreenV3(trim: trims[i]),
              ),
            );
          },
        ),
      );
    });
  }

  /// The buyer search is location-scoped by contract, so with neither
  /// coordinates nor a pincode there is nothing to ask for — prompt instead
  /// of showing an empty list the user can't act on.
  Widget _locationPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 44, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              'Turn on location to see vehicles near you',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size12),
            ElevatedButton(
              onPressed: () async {
                await LocationService.ensureUsableLocation();
                await _controller.loadDiscover();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Enable location',
                style: TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
