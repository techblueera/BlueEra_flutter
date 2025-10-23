import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/food/view/food_upload_screen.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/store/view/business_store_card.dart';
import 'package:BlueEra/features/common/store/view/store_food_service_card.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/common/store/view/store_screen_controller.dart';
import 'package:BlueEra/features/common/store/view/store_services_card.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/all_stores_feed_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
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

class _StoreFeedScreenState extends State<StoreFeedScreen> {
  late StoreScreenController controller;
  final viewBusinessDetailsController =
  Get.put(ViewBusinessDetailsController());
  final ViewPersonalDetailsController viewPersonalDetailsController =
  Get.isRegistered<ViewPersonalDetailsController>() ?
  Get.find<ViewPersonalDetailsController>() : Get.put(ViewPersonalDetailsController());
  double headerHeight = 0.0;

  @override
  void initState() {
    super.initState();
    controller = Get.put(StoreScreenController());
    controller.onHeaderVisibilityChanged = widget.onHeaderVisibilityChanged;
    controller.checkAndFetchAllStoresFeed();
    controller.scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
    });
  }

  void _scrollListener() {
      if (controller.scrollController.position.pixels >=
          controller.scrollController.position.maxScrollExtent - 200) {
        final index = controller.selectedStoreIndex.value;

        switch (index) {
          case 0:
            controller.getAllStoresFeedNearBy(isLoadMore: true);
            break;
          case 1:
            controller.getAllStoreProductNearBy(isLoadMore: true);
            break;
          case 2:
            controller.getAllServiceNearBy(isLoadMore: true);
            break;
          case 3:
            controller.getAllFoodService(isLoadMore: true);
            break;
          case 4:
            controller.getAllStoreNearBy(isLoadMore: true);
            break;
      }
    }

  }

  void _calculateHeaderHeight() {
    final renderBox =
        controller.headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      // controller.headerHeight.value = renderBox.size.height;
      // log('header height-- ${controller.headerHeight.value}');

      headerHeight = renderBox.size.height;
     setState(() {});
    }
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
    final height = SizeConfig.screenHeight;
    final isTablet = width > 600;

    double dynamicSize(double base) =>
        base * (width / 390); // Responsive scale base on 390px width

    return SafeArea(
      child: Scaffold(
        body: Obx(() {
          return Stack(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(
                    top: headerHeight *
                        (1 - controller.headerOffset.value),
                    // top: controller.headerHeight *
                    //     (1 - controller.headerOffset.value),
                  ),
                  child: setupScrollVisibilityNotification(
                    controller: controller.scrollController,
                    headerHeight: headerHeight,
                    // headerHeight: controller.headerHeight.value,
                    onVisibilityChanged: (visible, offset) {
                      final currentOffset = controller.headerOffset.value;

                      // Linear animation step (same speed up/down)
                      const step = 0.25;

                      double newOffset = currentOffset;
                      if (visible) {
                        // show header
                        newOffset = (currentOffset - step).clamp(0.0, 1.0);
                      } else {
                        // hide header
                        newOffset = (currentOffset + step).clamp(0.0, 1.0);
                      }

                      controller.headerOffset.value = newOffset;
                      controller.isHeaderVisible.value = visible;
                      widget.onHeaderVisibilityChanged?.call(visible);
                    },
                    child: SingleChildScrollView(
                      controller: controller.scrollController,
                      child: Column(
                        children: [
                          // Background Image
                          Container(
                            width: double.infinity,
                            height: dynamicSize(270),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                    AppImageAssets.storeNewBackground),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Obx(()=> LocationService.userCurrentAddress.isNotEmpty ? CustomText(
                                  'Find Anything\n in ' + LocationService.userCurrentAddress[2],
                                  fontSize: SizeConfig.extraLarge22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                  textAlign: TextAlign.center,
                                ) : SizedBox()),
                                Positioned(
                                    top: dynamicSize(12),
                                    right: dynamicSize(15),
                                    child: InkWell(
                                      onTap: ()=> LocationService.fetchLocation(),
                                      child: Container(
                                        padding: EdgeInsets.all(dynamicSize(5)),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          shape: BoxShape.circle
                                        ),
                                        child: LocalAssets(
                                          imagePath: AppIconAssets.currentLocationIcon,
                                        ),
                                      ),
                                    )
                                )
                              ],
                            ),
                          ),

                          // Foreground White Container (with overlap effect)
                          Transform.translate(
                            offset: Offset(0, -dynamicSize(20)),
                            // slight overlap for same look
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: dynamicSize(15)),
                              decoration: const BoxDecoration(
                                color: AppColors.whiteF1,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: dynamicSize(10)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 2,
                                        width: 60,
                                        color: AppColors.secondaryTextColor,
                                      )
                                    ],
                                  ),
                                  SizedBox(height: dynamicSize(24)),
                                  HorizontalTabSelector(
                                    tabs: controller.storeTab,
                                    selectedIndex:
                                        controller.selectedStoreIndex.value,
                                    horizontalMargin: 0.0,
                                    onTabSelected: (index, value) {
                                      controller.onStoreTabChanged(index);
                                    },
                                    labelBuilder: (label) => label,
                                  ),
                                  SizedBox(height: dynamicSize(18)),
                                  _buildStoreTab(dynamicSize),
                                  SizedBox(height: dynamicSize(10)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Sliding Header
                Obx(() => AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      top: -controller.headerOffset.value *
                          headerHeight,
                     // top: -controller.headerOffset.value *
                     //      controller.headerHeight.value,
                      left: 0,
                      right: 0,
                      child: KeyedSubtree(
                        key: controller.headerKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: SizeConfig.size10),
                            _buildStoreHeader(),
                            SizedBox(height: SizeConfig.size5),
                          ],
                        ),
                      ),
                    )),
              ],
            );
        }),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.paddingM,
        // vertical: SizeConfig.paddingXSmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: ()=> Get.to(()=> BusinessOwnProfileScreen()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size16),
                    child: CachedNetworkImage(
                      imageUrl: userProfileGlobal,
                      width: SizeConfig.size32,
                      height: SizeConfig.size32,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: SizeConfig.size32,
                        height: SizeConfig.size32,
                        color: Colors.grey[300],
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.person, size: SizeConfig.size32 / 2),
                    ),
                  ),

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
                 if(isBusinessUser()){
                   Get.toNamed(RouteHelper.getInventoryScreenRoute());
                 }else{
                   if (viewPersonalDetailsController
                       .personalProfileDetails.value.isProfileCreated ==
                       false) {
                     Get.to(()=> CreateProfileScreen());
                   } else {
                     Get.toNamed(RouteHelper.getEarnWithBlueEraNewScreenRoute());
                   }
                 }
               },
               title: "My Store",
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

      if (controller.isAllStoreFeedFirstLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryColor,
            ),
          ),
        );
      }

      Widget tabContent;

      switch (selectedTab) {
        case 0:
          final items = controller.allNearByStoresFeed;

          if (items.isEmpty) {
            tabContent = EmptyStateWidget(message: 'No store found');
            break;
          }

          // Group consecutive food items into pairs
          List<List<AllStoresFeedData>> groupedStoreFeed = [];
          List<AllStoresFeedData> tempStoreFeed = [];

          for (var item in items) {
            final type = StoreTypeExtension.fromString(item.type);

            if (type == StoreType.food) {
              tempStoreFeed.add(item);
              if (tempStoreFeed.length == 2) {
                groupedStoreFeed.add(List.from(tempStoreFeed));
                tempStoreFeed.clear();
              }
            } else {
              if (tempStoreFeed.isNotEmpty) {
                groupedStoreFeed.add(List.from(tempStoreFeed));
                tempStoreFeed.clear();
              }
              groupedStoreFeed.add([item]); // non-food item as its own block
            }
          }
          if (tempStoreFeed.isNotEmpty) groupedStoreFeed.add(List.from(tempStoreFeed));

          tabContent = Column(
            children: [
              ...groupedStoreFeed.map((block) {
                final first = block.first;
                final type = StoreTypeExtension.fromString(first.type);

                if (type == StoreType.food) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = block.length;
                        final crossSpacing = 10.0;
                        final itemWidth = (constraints.maxWidth -
                            ((crossAxisCount - 1) * crossSpacing)) /
                            crossAxisCount;

                        List<Widget> rowChildren = [];
                        for (int i = 0; i < block.length; i++) {
                          rowChildren.add(
                            SizedBox(
                              width: itemWidth,
                              child: StoreFoodServiceCard(
                                foodDetailsData: block[i].foodData ?? GetFoodDetailsModel(),
                                isShowVerticalUi: true,
                              ),
                            ),
                          );

                          if (i != block.length - 1) {
                            rowChildren.add(SizedBox(width: crossSpacing));
                          }
                        }

                        return Row(
                          children: rowChildren,
                        );
                      },
                    ),
                  );
                } else if (type == StoreType.business) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: BusinessStoreCard(
                      ds: ds,
                      getAllStoreResData:
                      first.businessData ?? GetAllStoreResModel(),
                    ),
                  );
                } else if (type == StoreType.service) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: StoreServicesCard(
                      serviceData: first.servicesData ?? GetServiceModel(),
                    ),
                  );
                } else if (type == StoreType.inventory) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: StoreProductCard(
                      productStore: first.inventoryData?.product ?? ProductStore(),
                      isShowBusinessInfo: true,
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              })
                  .toList(),


              if (controller.isAllStoreFeedLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ]
          );

          break;

        case 1:
          final productList = controller.storeProductDataList;

          if (controller.isStoreProductDataFirstLoading.value) {
            tabContent = const Center(
              child: CircularProgressIndicator(),
            );
            break;
          }

          if (productList.isEmpty) {
            tabContent = const EmptyStateWidget(message: 'No products found');
            break;
          }

          tabContent = Column(
            children: [
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  final productData = productList[index];

                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: StoreProductCard(
                      productStore: productData.product,
                      isShowBusinessInfo: true,
                    ),
                  );
                },
              ),

              if (controller.isStoreProductDataLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
          break;

        case 2:
          final serviceList = controller.serviceDataList;

          if (controller.isServiceDataFirstLoading.value) {
            tabContent = const Center(
              child: CircularProgressIndicator(),
            );
            break;
          }

          if (serviceList.isEmpty) {
            tabContent = const EmptyStateWidget(message: 'No services found');
            break;
          }

          tabContent = Column(
            children: [
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: serviceList.length,
                itemBuilder: (context, index) {
                  final serviceData = serviceList[index];

                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: StoreServicesCard(
                      serviceData: serviceData,
                    ),
                  );
                },
              ),

              if (controller.isServiceDataLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
          break;


        case 3:
          final foodList = controller.foodDataList;

          if (controller.isFoodDataFirstLoading.value) {
            tabContent = const Center(
              child: CircularProgressIndicator(),
            );
            break;
          }

          if (foodList.isEmpty) {
            tabContent = const EmptyStateWidget(message: 'No food items found');
            break;
          }

          tabContent = Column(
            children: [
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: foodList.length,
                itemBuilder: (context, index) {
                  final foodItem = foodList[index];

                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: StoreFoodServiceCard(
                      foodDetailsData: foodItem,
                      isShowVerticalUi: false
                    ),
                  );
                },
              ),

              if (controller.isFoodDataLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
          break;


        case 4:
          final storeList = controller.allStore; // or storeProductDataList if showing products

          if (controller.isAllStoreFirstLoading.value) {
            tabContent = const Center(
              child: CircularProgressIndicator(),
            );
            break;
          }

          if (storeList.isEmpty) {
            tabContent = const EmptyStateWidget(message: 'No stores found');
            break;
          }

          tabContent = Column(
            children: [
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: storeList.length,
                itemBuilder: (context, index) {
                  final storeData = storeList[index];

                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: BusinessStoreCard(
                      ds: ds,
                      getAllStoreResData: storeData,
                    ),
                  );
                },
              ),

              if (controller.isAllStoreLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
          break;


        default:
          tabContent = const SizedBox.shrink();
      }

      return tabContent;
    });
  }

}
