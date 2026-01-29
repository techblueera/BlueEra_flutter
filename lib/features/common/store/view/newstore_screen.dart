import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/store/view/business_store_card.dart';
import 'package:BlueEra/features/common/store/view/store_food_service_card.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/common/store/view/store_screen_controller.dart';
import 'package:BlueEra/features/common/store/view/store_services_card.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/all_stores_feed_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:BlueEra/widgets/update_live_photo_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/local_assets.dart';

class StoreFeedScreen extends StatefulWidget {
  final bool isHeaderVisible;
  final Function(bool isVisible)? onHeaderVisibilityChanged;

  const StoreFeedScreen(
      {super.key,
      required this.isHeaderVisible,
      this.onHeaderVisibilityChanged});

  @override
  State<StoreFeedScreen> createState() => _StoreFeedScreenState();
}

class _StoreFeedScreenState extends State<StoreFeedScreen>
    with SingleTickerProviderStateMixin {
  final StoreScreenController controller = Get.put(StoreScreenController());
  final viewBusinessDetailsController =
      Get.put(ViewBusinessDetailsController());
  final viewPersonalDetailsController = getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  double headerHeight = 0.0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    controller.onHeaderVisibilityChanged = widget.onHeaderVisibilityChanged;
    controller.checkAndFetchAllStoresFeed();
    controller.searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    controller.debounce?.cancel();
    controller.debounce = Timer(const Duration(milliseconds: 600), () {
      if (controller.searchController.text.length >= 3) {
        controller.getAllStoreProductNearBy(
          query: controller.searchController.text.trim(),
        );
      }
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    controller.onStoreTabChanged(_tabController.index);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    controller.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StoreFeedScreen oldWidget) {
    if (oldWidget.isHeaderVisible != widget.isHeaderVisible) {
      controller.isHeaderVisible.value = widget.isHeaderVisible;
      super.didUpdateWidget(oldWidget);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.screenWidth;

    double dynamicSize(double base) => base * (width / 390);

    return SafeArea(
      child: Scaffold(
        body: setupScrollVisibilityNotification(
          controller: controller.scrollController,
          onVisibilityChanged: (visible, offset) {
            controller.isHeaderVisible.value = visible;
            widget.onHeaderVisibilityChanged?.call(visible);
          },
          child: DefaultTabController(
            length: controller.storeTab.length,
            child: CustomScrollView(
              controller: controller.scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeaderSection(dynamicSize),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CustomTabBarDelegate(
                    _buildTabButtons(dynamicSize),
                  ),
                ),
                _buildStoreTab(dynamicSize),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.paddingM,
        vertical: SizeConfig.paddingXS,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => isIndividual()
                  ? Get.to(() => PersonalProfileSetupNewScreen())
                  : Get.to(() => BusinessOwnProfileScreen()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CachedAvatarWidget(
                      imageUrl: userProfileGlobal,
                      size: SizeConfig.size30,
                      borderRadius: SizeConfig.size15,
                      showProfileOnFullScreen: false),
                  SizedBox(width: SizeConfig.size8),
                  CustomText(
                    isBusiness() ? businessNameGlobal : userNameGlobal,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: SizeConfig.size8),

          CustomBtn(
            height: SizeConfig.size30,
            width: SizeConfig.size110,
            onTap: () {
              if (isGuestUser()) {
                createProfileScreen();
              } else if (isBusinessUser()) {
                final controller = Get.find<ViewBusinessDetailsController>();

                if ((controller.businessProfileDetails?.data?.livePhotos ?? [])
                        .length <
                    3) {
                  showLivePhotoDialog(
                    context: context,
                  );
                } else {
                  Get.toNamed(RouteHelper.getInventoryScreenRoute());
                }
              } else {
                if (viewPersonalDetailsController
                        .personalProfileDetails.value.isProfileCreated ==
                    false) {
                  Get.to(() => CreateProfileScreen());
                } else {
                  Get.toNamed(
                      RouteHelper.getEarnServiceAvailableOptionsScreenRoute()
                  );
                  // if(userProfessionGlobal == DELIVERY_RIDER){
                  //   Get.toNamed(RouteHelper
                  //       .getRiderServiceScreenRoute());
                  // }else{
                  //   Get.toNamed(RouteHelper
                  //       .getEarnServiceScreenRoute());
                  // }
                }
              }
            },
            title: AppStrings.myStore.tr,
            borderColor: AppColors.primaryColor,
            textColor: AppColors.primaryColor,
            bgColor: Colors.transparent,
            radius: SizeConfig.size10,
          ),

          // PopupMenuButton<String>(
          //   padding: EdgeInsets.zero,
          //   offset: const Offset(-6, 36),
          //   color: AppColors.white,
          //   elevation: 8,
          //   shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(10)),
          //   onSelected: (value) async {
          //     if (isGuestUser()) {
          //       createProfileScreen();
          //     } else if (value.toUpperCase() == "ADD PRODUCT") {
          //       Get.toNamed(
          //         RouteHelper.getAddProductScreenRoute(),
          //         arguments: {
          //           ApiKeys.id: businessId,
          //           ApiKeys.providerType: ProductServiceProviderType.business
          //         }
          //       );
          //     } else if (value.toUpperCase() == "ADD SERVICE") {
          //       Get.toNamed(
          //           RouteHelper.getAddServicesScreenRoute(),
          //           arguments: {
          //             ApiKeys.providerType: ProductServiceProviderType.business,
          //           }
          //       );
          //     } else if (value.toUpperCase() == "ADD FOOD") {
          //       Get.to(() => FoodUploadScreen(
          //         providerType: ProductServiceProviderType.business
          //       ));
          //     }
          //   },
          //   icon: LocalAssets(imagePath: AppIconAssets.addOutlinedIcon),
          //   itemBuilder: (context) => popupMenuInventoryItems(),
          // )
        ],
      ),
    );
  }

  Widget _buildStoreTab(double Function(double) ds) {
    return Obx(() {
      final selectedTab = controller.selectedStoreIndex.value;

      switch (selectedTab) {
        case 0: // All Stores
          return _buildAllStoresSliverList(ds);

        case 1: // Products
          return _buildProductsSliverList(ds);

        case 2: // Services
          return _buildServicesSliverList(ds);

        case 3: // Food
          return _buildFoodSliverList(ds);

        case 4: // Business
          return _buildBusinessSliverList(ds);

        default:
          return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
    });
  }

// Case 0: All Stores Feed
  Widget _buildAllStoresSliverList(double Function(double) ds) {
    if (controller.isAllStoreFeedFirstLoading.value) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        ),
      );
    }

    final groupedStoreFeed = controller.groupedStoreFeed;

    if (groupedStoreFeed.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: EmptyStateWidget(message: 'No store found'),
        ),
      );
    }

    return SliverPadding(
      padding:
          EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: ds(10)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == groupedStoreFeed.length) {
              return controller.isAllStoreFeedLoadingMore.value
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink();
            }

            final block = groupedStoreFeed[index];
            if (block.isEmpty) return const SizedBox.shrink();

            final first = block.first;
            final type = StoreTypeExtension.fromString(first.type);

            return _buildStoreBlock(context, type, block, first, ds);
          },
          childCount: groupedStoreFeed.length +
              (controller.isAllStoreFeedLoadingMore.value ? 1 : 0),
        ),
      ),
    );
  }

// Case 1: Products
  Widget _buildProductsSliverList(double Function(double) ds) {
    final productList =
        List<GetProductData>.from(controller.storeProductDataList);

    if (controller.isStoreProductDataFirstLoading.value) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (productList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: EmptyStateWidget(message: 'No products found'),
        ),
      );
    }

    return SliverPadding(
      padding:
          EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: ds(10)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= productList.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final productData = productList[index];
            log('loggggg 2--> ${productData.product.business_name}');
            return Padding(
              padding: EdgeInsets.only(bottom: ds(10)),
              child: StoreProductCard(
                  productStore: productData.product,
                  isShowInGrid: false
              ),
            );
          },
          childCount: productList.length +
              (controller.isStoreProductDataLoadingMore.value ? 1 : 0),
        ),
      ),
    );
  }

// Case 2: Services
  Widget _buildServicesSliverList(double Function(double) ds) {
    final serviceList = List<GetServiceModel>.from(controller.serviceDataList);

    if (controller.isServiceDataFirstLoading.value) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (serviceList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: EmptyStateWidget(message: AppStrings.notFoundAnyService),
        ),
      );
    }

    return SliverPadding(
      padding:
          EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: ds(10)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= serviceList.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final serviceData = serviceList[index];
            return Padding(
              padding: EdgeInsets.only(bottom: ds(10)),
              child: StoreServicesCard(serviceData: serviceData),
            );
          },
          childCount: serviceList.length +
              (controller.isServiceDataLoadingMore.value ? 1 : 0),
        ),
      ),
    );
  }

// Case 3: Food
  Widget _buildFoodSliverList(double Function(double) ds) {
    final foodList = List<GetFoodDetailsModel>.from(controller.foodDataList);

    if (controller.isFoodDataFirstLoading.value) {
      return const SliverToBoxAdapter(
        child: Center(
            child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        )),
      );
    }

    if (foodList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: EmptyStateWidget(message: 'No food items found'),
        ),
      );
    }

    return SliverPadding(
      padding:
          EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: ds(10)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= foodList.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final foodItem = foodList[index];
            return Padding(
              padding: EdgeInsets.only(bottom: ds(10)),
              child: StoreFoodServiceCard(
                foodDetailsData: foodItem,
                isShowInGrid: false,
              ),
            );
          },
          childCount: foodList.length +
              (controller.isFoodDataLoadingMore.value ? 1 : 0),
        ),
      ),
    );
  }

// Case 4: Business
  Widget _buildBusinessSliverList(double Function(double) ds) {
    final storeList = List<GetAllStoreResModel>.from(controller.allStore);

    if (controller.isAllStoreFirstLoading.value) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (storeList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: EmptyStateWidget(message: 'No stores found'),
        ),
      );
    }

    return SliverPadding(
      padding:
          EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: ds(10)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= storeList.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final storeData = storeList[index];
            final String businessId = storeData.id ?? '';
            return VisibilityDetector(
              key: Key('business_$businessId'),
              onVisibilityChanged: (info) {
                // Trigger API when 50% or more of the card is visible
                if (info.visibleFraction >= 0.5 && businessId.isNotEmpty) {
                  trackBusinessStoreView(businessId);
                }
              },
              child: Padding(
                padding: EdgeInsets.only(bottom: ds(10)),
                child: BusinessStoreCard(
                  ds: ds,
                  getAllStoreResData: storeData,
                ),
              ),
            );
          },
          childCount: storeList.length +
              (controller.isAllStoreLoadingMore.value ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildStoreBlock(
      BuildContext context,
      StoreType type,
      List<AllStoresFeedData> block,
      AllStoresFeedData first,
      double Function(double) ds) {
    final padding = EdgeInsets.only(bottom: ds(10));

    switch (type) {
      case StoreType.food:
        return Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = block.length;
              final crossSpacing = 10.0;
              final itemWidth = (constraints.maxWidth -
                      ((crossAxisCount - 1) * crossSpacing)) /
                  crossAxisCount;

              return Row(
                children: [
                  for (int i = 0; i < block.length; i++) ...[
                    SizedBox(
                      width: itemWidth,
                      child: StoreFoodServiceCard(
                        foodDetailsData:
                            block[i].foodData ?? GetFoodDetailsModel(),
                        isShowInGrid: true,
                      ),
                    ),
                    if (i != block.length - 1) SizedBox(width: crossSpacing),
                  ]
                ],
              );
            },
          ),
        );

      case StoreType.business:
        final businessData = first.businessData;

        // skip rendering if no valid live photos
        if (businessData?.livePhotos == null ||
            businessData!.livePhotos!.isEmpty ||
            !businessData.livePhotos!.any((p) => p.trim().isNotEmpty)) {
          return const SizedBox.shrink();
        }

        final businessId = businessData.id ?? '';

        return VisibilityDetector(
          key: Key('business_$businessId'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction >= 0.5 && businessId.isNotEmpty) {
              trackBusinessStoreView(businessId);
            }
          },
          child: Padding(
            padding: padding,
            child: BusinessStoreCard(
              ds: ds,
              getAllStoreResData: businessData,
            ),
          ),
        );

      case StoreType.service:
        return Padding(
          padding: padding,
          child: StoreServicesCard(
            serviceData: first.servicesData ?? GetServiceModel(),
          ),
        );

      case StoreType.inventory:
        return Padding(
          padding: padding,
          child:  StoreProductCard(
            productStore: first.inventoryData?.product ?? ProductStore(),
              isShowInGrid: false
          ),
        );
    }
  }

  // Widget _buildTabButtons() {
  //   return Obx(()=> HorizontalTabSelector(
  //     tabs: controller.storeTab,
  //     selectedIndex: controller.selectedStoreIndex.value,
  //     horizontalMargin: 0.0,
  //     onTabSelected: (index, value) {
  //       controller.onStoreTabChanged(index);
  //     },
  //     labelBuilder: (label) => label,
  //   ));
  // }

  Widget _buildTabButtons(double Function(double) ds) {
    return Container(
      width: SizeConfig.screenWidth,
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      // decoration: const BoxDecoration(
      //   color: AppColors.whiteF1,
      //   borderRadius: BorderRadius.only(
      //     topLeft: Radius.circular(20),
      //     topRight: Radius.circular(20),
      //   ),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ds(5)),
          SizedBox(
            height: SizeConfig.size30,
            child: ListView.builder(
              itemCount: controller.storeTab.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final isSelected = _tabController.index == index;
                // final isSelected = controller.selectedStoreIndex.value == index;
                return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        _tabController.animateTo(index);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size10,
                          vertical: SizeConfig.size5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size10),
                          color: controller.selectedStoreIndex.value == index
                              ? AppColors.primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.secondaryTextColor,
                          ),
                        ),
                        child: CustomText(
                          '${controller.storeTab[index]}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.secondaryTextColor,
                        ),
                      ),
                    ));
              },
            ),
          ),
          SizedBox(height: ds(5)),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(double Function(double) ds) {
    return Column(
      children: [
        if (!isGuestUser()) ...[
          _buildStoreHeader(),
        ],

        // Background Image
        Container(
          width: double.infinity,
          height: ds(280),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImageAssets.storeNewBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Obx(() {
                final address = LocationService.userCurrentAddress.value;

                return address.city.isNotEmpty
                    ? Padding(
                  padding: controller.selectedStoreIndex.value == 1
                      ? const EdgeInsets.only(bottom: 20.0)
                      : EdgeInsets.zero,
                  child: CustomText(
                    'Find Anything\n in ${address.city}',
                    fontSize: SizeConfig.extraLarge22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                    textAlign: TextAlign.center,
                  ),
                )
                    : const SizedBox();
              }),

              // Obx(()=> (controller.selectedStoreIndex.value == 1)
              //     ? Positioned(
              //     bottom: 60,
              //     left: 20,
              //     right: 20,
              //     child: CommonTextField(
              //       textEditController: controller.searchController,
              //       hintText: "Search Product...",
              //       showClearIcon: controller.searchText.isNotEmpty,
              //       isValidate: false,
              //       onChange: (value){
              //         controller.searchController.text = value;
              //         controller.searchText.value = value;
              //       },
              //       onClearTap: (){
              //         controller.searchController.clear();
              //         controller.searchText.value = '';
              //       },
              //     )
              // ) : SizedBox()),

              Positioned(
                  top: ds(12),
                  right: ds(15),
                  child: InkWell(
                    onTap: () => LocationService.fetchLocation(),
                    child: Container(
                      padding: EdgeInsets.all(ds(5)),
                      decoration: BoxDecoration(
                          color: AppColors.white, shape: BoxShape.circle),
                      child: LocalAssets(
                        imagePath: AppIconAssets.currentLocationIcon,
                      ),
                    ),
                  )),

              ///  Move your tab up using Positioned or Transform
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: ds(25),
                  decoration: const BoxDecoration(
                    color: AppColors.whiteF1,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: ds(10)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 2,
                            width: 60,
                            color: AppColors.secondaryTextColor,
                          ),
                          SizedBox(height: ds(5)),
                        ],
                      ),
                      // SizedBox(height: ds(16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  _CustomTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 50.0;

  @override
  double get maxExtent => 50.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: EdgeInsets.only(top: 8),
      color: AppColors.appBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_CustomTabBarDelegate oldDelegate) => true;
}
