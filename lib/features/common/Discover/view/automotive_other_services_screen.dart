import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/other_service_business_search_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/service_business_card.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';

/// Discover-side listing for the three "other service" automotive categories
/// (Vehicle Service, Vehicle Support, Transport Logistics Parking). Mirrors
/// the UX of [ServicesNearMeScreen] — banner + sticky category tabs +
/// paginated [ServiceBusinessCard] list — but the tabs are a fixed set
/// because these categories aren't part of the generic services taxonomy.
/// Backing API is the same: `GET /other-service/business-profile/search`
/// with `categoryOfBusiness=<wire>`.
class AutomotiveOtherServicesScreen extends StatefulWidget {
  /// Optional pre-selected category wire value
  /// (`VEHICLE_SERVICE` / `VEHICLE_SUPPORT` / `TRANSPORT_LOGISTICS_PARKING`).
  /// Defaults to the first tab when null or unmatched.
  final String? initialCategoryWire;

  const AutomotiveOtherServicesScreen({super.key, this.initialCategoryWire});

  @override
  State<AutomotiveOtherServicesScreen> createState() =>
      _AutomotiveOtherServicesScreenState();
}

class _AutomotiveOtherServicesScreenState
    extends State<AutomotiveOtherServicesScreen> {
  // Wire values match the API's `categoryOfBusiness` enum exactly.
  // (Not `const` — `AppImageAssets.*` are non-const String fields.)
  static final List<_AutomotiveOtherCategory> _categories = [
    _AutomotiveOtherCategory(
      name: 'Vehicle Service',
      wire: 'VEHICLE_SERVICE',
      icon: AppImageAssets.vehicleService,
    ),
    _AutomotiveOtherCategory(
      name: 'Vehicle Support',
      wire: 'VEHICLE_SUPPORT',
      icon: AppImageAssets.VehicleSupport,
    ),
    _AutomotiveOtherCategory(
      name: 'Transport Logistics',
      wire: 'TRANSPORT_LOGISTICS_PARKING',
      icon: AppImageAssets.TransportLogistic,
    ),
  ];

  final controller = getOrPut(() => OtherServiceBusinessSearchController());
  final RxInt _selectedIndex = 0.obs;

  // Vehicle-themed banners — same set as the vehicle listing screen so the
  // whole automotive section reads as one flow.
  final List<String> _bannerImages = const [
    'https://img.magnific.com/free-vector/seller-talking-customer-about-car-dealer-future-vehicle-owner-rental-center-service_575670-280.jpg?semt=ais_hybrid&w=740&q=80',
    'https://img.magnific.com/free-photo/benchman-fixing-engine-car_114579-2807.jpg',
    'https://img.magnific.com/free-photo/hands-female-mechanic-using-laptop_1170-1248.jpg',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategoryWire;
    if (initial != null) {
      final idx = _categories.indexWhere((c) => c.wire == initial);
      if (idx >= 0) _selectedIndex.value = idx;
    }
    controller.fetchInitial(_categories[_selectedIndex.value].wire);
  }

  void _onCategoryTap(int index) {
    _selectedIndex.value = index;
    controller.fetchInitial(_categories[index].wire);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.fetchMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final width = SizeConfig.screenWidth;
    double dynamicSize(double base) => base * (width / 390);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                // The header paints a search bar; this is what it opens —
                // the shared store search, scoped to this vertical by its
                // StoreSearchConfig. Tapping a result opens that profile.
                onSearchTap: () => Get.to(
                    () => StoreSearchScreen(config: StoreSearchConfig.automotive())),
                categories: _categories
                    .map((c) => StickyCategory(
                          id: c.wire,
                          name: c.name,
                          imageUrl: c.icon,
                        ))
                    .toList(),
                selectedId: _categories[_selectedIndex.value].wire,
                onCategoryTap: (item) {
                  final idx = _categories.indexWhere((c) => c.wire == item.id);
                  if (idx >= 0) _onCategoryTap(idx);
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
          body: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: _buildStoreContent(dynamicSize),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreContent(double Function(double) dynamicSize) {
    return Obx(() {
      if (controller.isLoading.value && controller.profiles.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.profiles.isEmpty) {
        final categoryName = _categories[_selectedIndex.value].name;
        return Center(
          child: EmptyStateWidget(
            message: AppStrings.noServicesFoundForCategory
                .trParams({'category': categoryName}),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.paddingXSL),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                left: SizeConfig.size12,
                right: SizeConfig.size12,
                bottom: SizeConfig.paddingL,
              ),
              itemCount: controller.profiles.length +
                  (controller.isLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.profiles.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final item = controller.profiles[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: dynamicSize(12)),
                  child: ServiceBusinessCard(
                    item: item,
                    index: index,
                    // Businesses in this section rarely upload a cover
                    // photo, so an empty grey box looked broken. Fall back
                    // to a vehicle-themed banner image instead — same set
                    // the top carousel uses, keyed by the selected tab so
                    // Vehicle Service / Support / Transport each get a
                    // themed placeholder.
                    fallbackHeroImageUrl: _bannerImages[
                        _selectedIndex.value % _bannerImages.length],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

/// Tab descriptor — name shown in the sticky header, wire value sent to the
/// API, and the local icon asset for the tab tile.
class _AutomotiveOtherCategory {
  final String name;
  final String wire;
  final String icon;

  const _AutomotiveOtherCategory({
    required this.name,
    required this.wire,
    required this.icon,
  });
}
