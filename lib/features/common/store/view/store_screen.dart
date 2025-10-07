import 'dart:developer';

import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/business_service/widget/service_card.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/product_listing/widgets/product_card.dart';
import 'package:BlueEra/features/common/store/store_search_suggestion/store_search_suggestion_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_carousel_slider.dart';
import '../../../business/visit_business_profile/view/visit_business_profile_new.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../food/view/widget/food_product_card.dart';
import 'store_screen_controller.dart';

class StoreScreen extends StatefulWidget {
  final bool isHeaderVisible;
  final Function(bool isVisible)? onHeaderVisibilityChanged;

  StoreScreen({
    super.key,
    required this.isHeaderVisible,
    this.onHeaderVisibilityChanged,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late StoreScreenController controller;

  // String? adUnitId;

  @override
  void initState() {
    super.initState();
    controller = Get.put(StoreScreenController());
    apiCalling();
    controller.onHeaderVisibilityChanged = widget.onHeaderVisibilityChanged;
    // adUnitId = getNativeAdUnitId();
  }

  @override
  void didUpdateWidget(covariant StoreScreen oldWidget) {
    if (oldWidget.isHeaderVisible != widget.isHeaderVisible) {
      controller.isHeaderVisible.value = widget.isHeaderVisible;
      super.didUpdateWidget(oldWidget);
    }
  }

  apiCalling() async {
    await controller.fetchStoresAndProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Obx(() {
        if (controller.isLoading.value) {
          return CircularIndicator();
        }

        return SafeArea(
          top: true,
          child: Stack(
            children: [
              /// Main Scrollable Area with Dynamic Padding

              AnimatedPadding(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: EdgeInsets.only(
                    top: controller.isHeaderVisible.value
                        ? controller.headerHeight.value
                        : 0),
                child: SingleChildScrollView(
                  controller: controller.scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: SizeConfig.size50),
                      _buildSearchBar(),

                      SizedBox(height: SizeConfig.size20),
                      _buildFoodServiceSection(categoryName: "Food"),


                       SizedBox(height: SizeConfig.size20),
                      _buildStoresProductSection(categoryName: "Product"),

                      SizedBox(height: SizeConfig.size20),
                      _buildStoresServiceSection(categoryName: "Service"),

                      // ProductSlider(),
                      _buildStoresSection(
                          categoryName: "Shop", tagName: "store"),

                      ///DO NOT DELETE THIS CODE....
                      /*      if (Platform.isAndroid) ...[
                        if (adUnitId != null) ...[
                          SizedBox(height: SizeConfig.size20),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: SizeConfig.size370,
                              maxHeight: SizeConfig.size450,
                            ),
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.paddingM),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: NativeAdWidget(adUnitId: adUnitId!),
                            ),
                          ),
                        ],
                      ],
*/
                      SizedBox(height: SizeConfig.size20),

                      // Transform.translate(
                      //   offset: Offset(0, -20),
                      //
                      //   // Negative offset to reduce space
                      //   child: CustomImageSlideshow(
                      //     isLoading: false,
                      //     height: SizeConfig.size200,
                      //     imagePaths: [
                      //       "assets/images/BANNER_1.jpeg",
                      //       "assets/images/BANNER_2.jpeg"
                      //     ],
                      //     isLocal: true,
                      //
                      //   ),
                      // ),

                      // _buildStoresSection(
                      //     categoryName: "Products", tagName: "products"),

                      // SizedBox(height: SizeConfig.size20),
                      // Transform.translate(
                      //   offset: Offset(0, -20),
                      //   // Negative offset to reduce space
                      //   child: CustomImageSlideshow(
                      //     isLoading: false,
                      //     imagePaths: [
                      //       AppImageAssets.dummy_burger_king,
                      //       AppImageAssets.dummy_burger_king,
                      //     ],
                      //     isLocal: true,
                      //   ),
                      // ),
                      _buildStoresSection(
                          categoryName: "Business", tagName: "services"),

                      /*     if (Platform.isAndroid) ...[
                        if (adUnitId != null) ...[
                          SizedBox(height: SizeConfig.size20),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: SizeConfig.size370,
                              maxHeight: SizeConfig.size450,
                            ),
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.paddingM),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: NativeAdWidget(adUnitId: adUnitId!),
                            ),
                          ),
                        ],
                      ],*/

                      SizedBox(height: SizeConfig.size20),

                      _buildStoresSection(
                          categoryName: "Others", tagName: "others"),
                    ],
                  ),
                ),
              ),

              /// Sliding Header
              Obx(() => AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    top: controller.isHeaderVisible.value
                        ? 0
                        : -controller.headerHeight.value,
                    left: 0,
                    right: 0,
                    child: KeyedSubtree(
                      key: controller.headerKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: SizeConfig.size10),
                          _buildLocationHeader(),
                          // SizedBox(height: SizeConfig.size10),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLocationHeader() {
    return InkWell(
      onTap: () async {
        apiCalling();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.paddingM,
          // vertical: SizeConfig.paddingXS,
        ),
        child: Row(
          children: [
            Icon(
              Icons.gps_fixed,
              color: Colors.black,
              size: SizeConfig.size24,
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    LocationService.userCurrentAddress.isNotEmpty
                        ? LocationService.userCurrentAddress
                            .take(3)
                            .where((e) => e.isNotEmpty)
                            .join(', ')
                        : "Get current location",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            /* Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(() => StoreWishlistScreen());
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryColor)),
                    child: CustomText(
                      "Wishlist",
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: SizeConfig.screenHeight * 0.25,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppImageAssets.storebackground),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      "Search in ${LocationService.userCurrentAddress.isNotEmpty && LocationService.userCurrentAddress[1].isNotEmpty ? LocationService.userCurrentAddress[1] : "your city.."}",
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                    SizedBox(height: SizeConfig.size15),
                    // In the _buildSearchBar() method, update the onTap handler:

                    GestureDetector(
                      onTap: () {
                        Get.to(() => BusinessChatProfile(
                              userId: '',
                            ));
                        // Get.to(() =>   StoreSearchSuggestionScreen());
                      },
                      child: AbsorbPointer(
                        child: Container(
                            width: Get.width,
                            height: SizeConfig.size40,
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size10),
                            margin: EdgeInsets.symmetric(
                                horizontal: SizeConfig.paddingL),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.size10),
                            ),
                            child: Row(
                              children: [
                                LocalAssets(
                                  imagePath: AppIconAssets.search,
                                  imgColor: AppColors.secondaryTextColor,
                                  height: SizeConfig.size18,
                                ),
                                SizedBox(
                                  width: SizeConfig.size8,
                                ),
                                Expanded(
                                    child: CustomText(
                                  "Search anything here...",
                                  fontSize: SizeConfig.size15,
                                  color: AppColors.secondaryTextColor,
                                )),
                                // LocalAssets(
                                //   height: SizeConfig.size18,
                                //   imagePath: AppIconAssets.mic,
                                //   imgColor: AppColors.secondaryTextColor,
                                // ),
                              ],
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoresProductSection({String? categoryName, String? tagName}) {
    if (controller.storeProductDataList.isNotEmpty)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
            child: CustomText(
              categoryName,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: SizeConfig.size15),
          Obx(() {
            return SizedBox(
              height: 285,
              child: controller.storeProductDataList.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
                      itemCount: controller.storeProductDataList.length,
                      itemBuilder: (context, index) {
                        return ProductCardBusiness(
                          productData: controller.storeProductDataList[index],
                          isGridView: false,
                          isShowChat: false,
                          isShowKM: true,
                          isShowBusinessInfo: true,
                        );

                      },
                    )
                  : Center(child: CustomText("No $tagName found yet")),
            );
          }),
          SizedBox(height: SizeConfig.size10),
        ],
      );
    return SizedBox.shrink();
  }
  Widget _buildStoresServiceSection({String? categoryName, String? tagName}) {
    if (controller.serviceDataList.isNotEmpty)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
            child: CustomText(
              categoryName,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: SizeConfig.size15),
          Obx(() {
            return SizedBox(
              height: 315,
              child: controller.serviceDataList.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
                      itemCount: controller.serviceDataList.length,
                      itemBuilder: (context, index) {
                        return ServiceCardBusiness(
                          serviceData: controller.serviceDataList[index],
                          isGridView: false,
                          isShowChat: false,
                          isShowKM: true,
                          isShowBusinessInfo: true,
                        );

                      },
                    )
                  : Center(child: CustomText("No $tagName found yet")),
            );
          }),
          SizedBox(height: SizeConfig.size10),
        ],
      );
    return SizedBox.shrink();
  }
  Widget _buildFoodServiceSection({String? categoryName, String? tagName}) {
    final chatViewController = Get.find<ChatViewController>();
    if (controller.foodList.isNotEmpty)


      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
            child: CustomText(
              categoryName,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: SizeConfig.size15),
          Obx(() {
            return SizedBox(
              height: 310,
              child: controller.foodList.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
                      itemCount: controller.foodList.length,
                      itemBuilder: (context, index) {
                        return FoodCardBusiness(
                          serviceData: controller.foodList[index],
                          isGridView: false,
                          isShowChat: false,
                          isShowKM: true,
                          isShowBusinessInfo: true,
                        );

                      },
                    )
                  : Center(child: CustomText("No $tagName found yet")),
            );
          }),
          SizedBox(height: SizeConfig.size10),
        ],
      );
    return SizedBox.shrink();
  }

  Widget _buildStoresSection({String? categoryName, String? tagName}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
          child: CustomText(
            categoryName,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SizeConfig.size15),
        Obx(() {
          List<GetAllStoreResModel> tempStoreList = <GetAllStoreResModel>[];
          if (tagName == "services") {
            tempStoreList.addAll(controller.getAllStore
                .where(
                    (data) => data.typeOfBusiness?.toLowerCase() == "service")
                .toList());
          }
          if (tagName == "store") {
            tempStoreList.addAll(controller.getAllStore
                .where(
                    (data) => data.typeOfBusiness?.toLowerCase() == "product")
                .toList());
          }
          if (tagName == "others") {
            tempStoreList.addAll(controller.getAllStore
                .where((data) => data.typeOfBusiness?.toLowerCase() == "both")
                .toList());
          }

          return SizedBox(
            height: 290,
            child: tempStoreList.isNotEmpty
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
                    itemCount: tempStoreList.length,
                    itemBuilder: (context, index) {
                      GetAllStoreResModel storeData = tempStoreList[index];
                      return GestureDetector(
                        onTap: () {
                          if (businessId == storeData.id) {
                            navigatePushTo(context, BusinessOwnProfileScreen());
                          } else {
                            Get.to(() => VisitBusinessProfileNew(
                                  businessId: storeData.id ?? "",
                                  screenName: AppConstants.feedScreen,
                                ));
                          }
                        },
                        child: Container(
                          width: 180,
                          margin: EdgeInsets.only(
                            right: index < tempStoreList.length - 1
                                ? SizeConfig.size12
                                : 0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Store Image

                              (storeData.livePhotos?.isNotEmpty ?? false)
                                  ? CustomImageSlideshow(
                                      isLoading: false,
                                      width: double.infinity,
                                      height: 140,
                                      imagePaths: storeData.livePhotos!,
                                      isLocal: false,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    )
                                  : Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          storeData.logo ?? "",
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(SizeConfig.size12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Category Tag
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.size8,
                                          vertical: SizeConfig.size4,
                                        ),
                                        decoration: BoxDecoration(
                                            // color: Colors.lightBlue,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: AppColors.primaryColor)),
                                        child: CustomText(
                                          storeData.categoryOfBusiness?.name,
                                          fontSize: SizeConfig.extraSmall8,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w500,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),

                                      SizedBox(height: SizeConfig.size8),

                                      // Store Name and Rating
                                      CustomText(
                                        storeData.businessName,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // SizedBox(height: SizeConfig.size4),

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          CustomText(
                                            ((storeData.totalRatings ?? 0) > 0)
                                                ? "(${storeData.totalRatings})"
                                                : "No Rating",
                                            fontSize: SizeConfig.small,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.black,
                                          ),
                                          SizedBox(width: 4),
                                          LocalAssets(
                                              imagePath: AppIconAssets
                                                  .distanceLocation),
                                          CustomText(
                                            (storeData.distance != null)
                                                ? (storeData.distance as num)
                                                    .toDouble()
                                                    .toStringAsFixed(2)
                                                : '0.0',
                                            fontSize: SizeConfig.extraSmall,
                                            color: AppColors.black30,
                                          ),
                                        ],
                                      ),

                                      // SizedBox(height: SizeConfig.size8),
                                      //
                                      // // Operating Hours
                                      // CustomText(
                                      //   store["status"]!,
                                      //   fontSize: SizeConfig.small,
                                      //   color: Colors.green,
                                      //   fontWeight: FontWeight.w500,
                                      // ),

                                      SizedBox(height: SizeConfig.size8),

                                      // Address
                                      CustomText(
                                        (storeData.address?.isNotEmpty ?? false)
                                            ? storeData.address
                                            : "N/A",
                                        fontSize: SizeConfig.medium,
                                        color: AppColors.secondaryTextColor,
                                        fontWeight: FontWeight.w400,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Center(child: CustomText("No $tagName found yet")),
          );
        }),
      ],
    );
  }
}
