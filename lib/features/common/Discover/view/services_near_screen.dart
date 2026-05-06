import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/view/product_store_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ServicesNearMeScreen extends StatefulWidget {
  final String? serviceCategoryName;
  final String? serviceCategory;

  const ServicesNearMeScreen({
    super.key,
    this.serviceCategoryName,
    this.serviceCategory,
  });

  @override
  State<ServicesNearMeScreen> createState() => _ServicesNearMeScreenState();
}

class _ServicesNearMeScreenState extends State<ServicesNearMeScreen> {
  final controller = getOrPut(() => NewStoreController());
  final AuthController _authController = Get.find<AuthController>();
  final RxInt _selectedIndex = 0.obs;

  List<CategoryData> get _categories =>
      _authController.businessOnboardingServicesCategories;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/portrait-smiling-female-doctor-with-stethoscope_1262-21077.jpg?w=1380",
    "https://img.freepik.com/free-photo/handyman-tools-isolated-white-background_1232-3596.jpg?w=1380",
    "https://img.freepik.com/free-photo/woman-getting-haircut-salon_23-2148928677.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    controller.typeOfBusiness = BusinessType.Service.name;

    if (widget.serviceCategory != null && _categories.isNotEmpty) {
      controller.businessCategoryId = widget.serviceCategory;
      final idx =
          _categories.indexWhere((c) => c.tagId == widget.serviceCategory);
      if (idx >= 0) _selectedIndex.value = idx;
    } else if (_categories.isNotEmpty) {
      controller.businessCategoryId = _categories.first.tagId;
    }

    controller.getAllStoreNearBy();
  }

  void _onCategoryTap(CategoryData item, int index) {
    _selectedIndex.value = index;
    controller.businessCategoryId = item.tagId;
    controller.getAllStoreNearBy();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
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
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                categories: _categories
                    .map((c) => StickyCategory(
                          id: c.tagId ?? '',
                          name: c.name ?? '',
                          imageUrl: c.imageUrl,
                        ))
                    .toList(),
                selectedId: _categories.isNotEmpty &&
                        _selectedIndex.value < _categories.length
                    ? _categories[_selectedIndex.value].tagId
                    : null,
                onCategoryTap: (item) {
                  final idx =
                      _categories.indexWhere((c) => c.tagId == item.id);
                  if (idx >= 0) _onCategoryTap(_categories[idx], idx);
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
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.allStore.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message:
                "No ${(_selectedIndex.value >= 0 && _selectedIndex.value < _categories.length) ? _categories[_selectedIndex.value].name ?? '' : ''} services found",
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
              itemCount: controller.allStore.length +
                  (controller.isAllStoreLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.allStore.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final storeData = controller.allStore[index];
                final String businessId = storeData.id ?? "";

                return VisibilityDetector(
                  key: Key("business_$businessId"),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction >= 0.5 &&
                        businessId.isNotEmpty) {
                      controller.trackStoreListView(businessId);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(bottom: dynamicSize(10)),
                    child: ProductStoreCard(
                      ds: dynamicSize,
                      index: index,
                      getAllStoreResData: storeData,
                    ),
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
