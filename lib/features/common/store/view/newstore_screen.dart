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

class _StoreFeedScreenState extends State<StoreFeedScreen> with SingleTickerProviderStateMixin{
  late StoreScreenController controller;
  final viewBusinessDetailsController =
  Get.put(ViewBusinessDetailsController());
  final ViewPersonalDetailsController viewPersonalDetailsController =
  Get.isRegistered<ViewPersonalDetailsController>() ?
  Get.find<ViewPersonalDetailsController>() : Get.put(ViewPersonalDetailsController());
  double headerHeight = 0.0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    controller = Get.put(StoreScreenController());
    controller.onHeaderVisibilityChanged = widget.onHeaderVisibilityChanged;
    controller.checkAndFetchAllStoresFeed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    controller.onStoreTabChanged(_tabController.index);
    setState(() {});
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

    double dynamicSize(double base) =>
        base * (width / 390); // Responsive scale base on 390px width

    return SafeArea(
      child: Scaffold(
        body: setupScrollVisibilityNotification(
            controller: controller.scrollController,
            headerHeight: headerHeight,
            // headerHeight: controller.headerHeight.value,
            onVisibilityChanged: (visible, offset) {
              // final currentOffset = controller.headerOffset.value;
              //
              // // Linear animation step (same speed up/down)
              // const step = 0.25;
              //
              // double newOffset = currentOffset;
              // if (visible) {
              //   // show header
              //   newOffset = (currentOffset - step).clamp(0.0, 1.0);
              // } else {
              //   // hide header
              //   newOffset = (currentOffset + step).clamp(0.0, 1.0);
              // }
              //
              // controller.headerOffset.value = newOffset;
              controller.isHeaderVisible.value = visible;
              widget.onHeaderVisibilityChanged?.call(visible);
            },
            child:
        DefaultTabController(
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
                  SliverToBoxAdapter(
                    child: _buildStoreTab(dynamicSize), // NO SingleChildScrollView here
                  ),
                ]
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      child: Obx(() {
        final selectedTab = controller.selectedStoreIndex.value;

        if (controller.isAllStoreFeedFirstLoading.value) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
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

            tabContent = ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: ds(10)),
               physics: const NeverScrollableScrollPhysics(),
              itemCount: groupedStoreFeed.length + (controller.isAllStoreFeedLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= groupedStoreFeed.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final block = groupedStoreFeed[index];
                final first = block.first;
                final type = StoreTypeExtension.fromString(first.type);

                // 🔹 FOOD type
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
                }

                // 🔹 BUSINESS type
                else if (type == StoreType.business) {
                  trackBusinessStoreView(first.businessData?.id??'');
                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: BusinessStoreCard(
                      ds: ds,
                      getAllStoreResData: first.businessData ?? GetAllStoreResModel(),
                    ),
                  );
                }

                // 🔹 SERVICE type
                else if (type == StoreType.service) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: StoreServicesCard(
                      serviceData: first.servicesData ?? GetServiceModel(),
                    ),
                  );
                }

                // 🔹 INVENTORY type
                else if (type == StoreType.inventory) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: ds(10)),
                    child: StoreProductCard(
                      productStore:
                      first.inventoryData?.product ?? ProductStore(),
                      isShowBusinessInfo: true,
                    ),
                  );
                }

                else {
                  return const SizedBox.shrink();
                }
              },
            );
            break;

          case 1:
            final productList = controller.storeProductDataList;

            if (controller.isStoreProductDataFirstLoading.value) {
              tabContent = const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ));
              break;
            }

            if (productList.isEmpty) {
              tabContent = const EmptyStateWidget(message: 'No products found');
              break;
            }

            tabContent = ListView.builder(
              controller: controller.productScroll,
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: ds(10)),
              itemCount: productList.length +
                  (controller.isStoreProductDataLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= productList.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final productData = productList[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: ds(10)),
                  child: StoreProductCard(
                    productStore: productData.product,
                    isShowBusinessInfo: true,
                  ),
                );
              },
            );
            break;


          case 2:
                final serviceList = controller.serviceDataList;

                if (controller.isServiceDataFirstLoading.value) {
                  tabContent = const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ));
                  break;
                }

                if (serviceList.isEmpty) {
                  tabContent = const EmptyStateWidget(message: 'No services found');
                  break;
                }

              tabContent = ListView.builder(
                  controller: controller.serviceScroll,
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: ds(10)),
                  itemCount:
                  serviceList.length + (controller.isServiceDataLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
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
                );
                break;

              case 3:
                final foodList = controller.foodDataList;

                if (controller.isFoodDataFirstLoading.value) {
                  tabContent = const Center(child: CircularProgressIndicator());
                  break;
                }

                if (foodList.isEmpty) {
                  tabContent = const EmptyStateWidget(message: 'No food items found');
                  break;
                }

                tabContent = ListView.builder(
                  controller: controller.foodScroll,
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: ds(10)),
                  itemCount:
                  foodList.length + (controller.isFoodDataLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
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
                        isShowVerticalUi: false,
                      ),
                    );
                  },
                );
                break;

              case 4:
                final storeList = controller.allStore;

                if (controller.isAllStoreFirstLoading.value) {
                  tabContent = const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ));
                  break;
                }

                if (storeList.isEmpty) {
                  tabContent = const EmptyStateWidget(message: 'No stores found');
                  break;
                }

                tabContent = ListView.builder(
                  controller: controller.storeScroll,
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: ds(10)),
                  itemCount:
                  storeList.length + (controller.isAllStoreLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loader at bottom
                    if (index >= storeList.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final storeData = storeList[index];
                    // trackBusinessStoreView(storeData.id??'');
                    return Padding(
                      padding: EdgeInsets.only(bottom: ds(10)),
                      child: BusinessStoreCard(
                        ds: ds,
                        getAllStoreResData: storeData,
                      ),
                    );
                  },
                );
                break;


          default:
            tabContent = const SizedBox.shrink();
        }

        return tabContent;
      }),
    );
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
    return
        Container(
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
                          borderRadius: BorderRadius.circular(SizeConfig.size10),
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
                    )
                );
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
        if (!isGuestUser())
          ...[
            _buildStoreHeader(),
          ],

        // Background Image
        Container(
          width: double.infinity,
          height: ds(280),
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
                  top: ds(12),
                  right: ds(15),
                  child: InkWell(
                    onTap: ()=> LocationService.fetchLocation(),
                    child: Container(
                      padding: EdgeInsets.all(ds(5)),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle
                      ),
                      child: LocalAssets(
                        imagePath: AppIconAssets.currentLocationIcon,
                      ),
                    ),
                  )
              ),

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

