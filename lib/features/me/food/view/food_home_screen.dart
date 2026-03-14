import 'dart:math';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/view/food_contact_us_screen.dart';
import 'package:BlueEra/features/me/food/view/food_service_gallery/food_service_photos_screen.dart';
import 'package:BlueEra/features/me/food/view/my_food_product_screen.dart';
import 'package:BlueEra/features/me/food/view/widget/food_home_profile_header.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class RestaurantHomeScreen extends StatefulWidget {
  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  final controller = getOrPut(() => RestaurantController());

  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  initState(){
    super.initState();
    controller.fetchHomeData(businessId: businessId);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        if(controller.foodHomeDataResponse.value.status == Status.INITIAL){
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.restaurantData.value;
        if (data == null)
          return Center(child: CustomText(AppStrings.noDataFound.tr));
        return RefreshIndicator(
          onRefresh: () async {
            controller.fetchHomeData(businessId: businessId);
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///FOOD HOTEL....
                CommonCardWidget(
                  cardMargin: 10,
                  padding: 0,
                  child: FoodHomeProfileHeader(
                    details: data.businessProfileDetails,
                    controller: viewBusinessDetailsController,
                  ),
                ),

                ///Food Selection (Horizontal List)
                if (controller.allFoodItems.isNotEmpty)
                  CustomFormCard(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(AppStrings.foodSelection.tr,
                            fontSize: 18, fontWeight: FontWeight.bold),
                        SizedBox(
                          height: 10,
                        ),
                        _buildHorizontalFoodList(),
                      ],
                    ),
                  ),

                ///FOOD MENU...
                if (controller.foodMenuNestedCategory.isNotEmpty)
                  _buildMenuCategories(controller.foodMenuNestedCategory),

                /// Gallery
                (data.gallery?.isNotEmpty ?? false)
                    ? CommonCardWidget(
                        // cardMargin: 0,
                        // padding: 10,
                        padding: 15,

                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(AppStrings.gallery.tr,
                                    fontSize: 20, fontWeight: FontWeight.bold),
                                InkWell(
                                    onTap: () {
                                      Get.to(FoodServicePhotosPhotoScreen());
                                    },
                                    child: LocalAssets(
                                      imagePath: AppIconAssets.editIcon,
                                      imgColor: AppColors.mainTextColor,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildGallery(data.gallery ?? [], context),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0
                        ),
                        child: PositiveCustomBtn(
                            onTap: () {
                              Get.to(FoodServicePhotosPhotoScreen());
                            },
                            title: AppStrings.addGalleryPhoto.tr),
                      ),

                SizedBox(height: 10.0),

                _buildContactNdMapCard(data.businessProfileDetails),

                SizedBox(
                  height: 100,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGallery(List<FoodGallery> galleryList, BuildContext context) {
    // Flatten all images
    List<String> allImages = [];
    for (var g in galleryList) {
      if (g.imageUrls != null) {
        allImages.addAll(g.imageUrls!);
      }
    }

    if (allImages.isEmpty) return const SizedBox();

    // Randomize and pick 6
    allImages.shuffle(Random());

    return StaggeredGrid.count(
      // shrinkWrap: true,
      // physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children:
          List.generate(allImages.length > 10 ? 10 : allImages.length, (index) {
        // Logic to replicate the pattern in your image:
        // Large Vertical (index 0), Two small (index 1,2), Large Horizontal (index 3)...
        int crossAxisCellCount = 2;
        num mainAxisCellCount = 2;

        if (index % 6 == 0 || index % 6 == 5) {
          // Large Vertical Tiles
          crossAxisCellCount = 2;
          mainAxisCellCount = 3;
        } else if (index % 6 == 3) {
          // Large Full-Width Horizontal Tile
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else {
          // Standard Small Squares
          crossAxisCellCount = 2;
          mainAxisCellCount = 1.5;
        }

        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          child: InkWell(
            onTap: () {
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: AppStrings.imageViewer,
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: allImages,
                  initialIndex: index,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                allImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContactNdMapCard(BusinessProfileDetails? businessProfileDetails) {
    final logoUrl = businessProfileDetails?.logo;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
              AppStrings.contactUs.tr,
              fontSize: SizeConfig.large,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w600),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.greyE5),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [AppShadows.textFieldShadow]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      key: ValueKey(logoUrl),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white, // Background color for placeholder transparency
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                        image: DecorationImage(
                          image: (logoUrl != null && logoUrl.isNotEmpty)
                              ? NetworkImage(logoUrl) as ImageProvider
                              : AssetImage(AppIconAssets.place_holder_image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomText(
                              businessProfileDetails?.businessName,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          const SizedBox(height: 5),
                          (businessProfileDetails?.businessDescription?.isNotEmpty ??false)
                              ? ExpandableText(
                            text: businessProfileDetails?.businessDescription??'',
                            trimLines: 3,
                            isReadMoreNewLine: false,
                            expandMode: ExpandMode.dialog,
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppConstants.OpenSans,
                            ),
                          )
                              : CustomText(
                            AppStrings.na,
                            color: AppColors.secondaryTextColor,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppConstants.OpenSans,
                          ),
                        ],
                      ),
                    )
                  ],
                ),

                const Divider(
                    color: AppColors.greyE5,
                    height: 30),

                // Contact List
                if(businessProfileDetails?.websiteUrl?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.website_click,
                      businessProfileDetails?.websiteUrl ?? "",
                      AppColors.primaryColor),

                if(businessProfileDetails?.subCategoryDetails?.name?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.principal,
                      businessProfileDetails?.subCategoryDetails?.name ?? "",
                      AppColors.secondaryTextColor),

                if(businessProfileDetails?.ownerDetails?[0].email?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.email,
                      businessProfileDetails?.ownerDetails?[0].email ?? "",
                      AppColors.secondaryTextColor),

                if(businessProfileDetails?.businessNumber?.officeMobNo?.number?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.phone_outline,
                      businessProfileDetails?.businessNumber?.officeMobNo?.number ?? "",
                      AppColors.secondaryTextColor),

                if(businessProfileDetails?.address?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.location_new,
                      businessProfileDetails?.address ?? "",
                      AppColors.secondaryTextColor),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          // SizedBox(
          //   width: double.infinity,
          //   height: 180,
          //   child: Stack(
          //     children: [
          //       GoogleMap(
          //         onMapCreated: _onMapCreated,
          //         initialCameraPosition: CameraPosition(
          //           target: LatLng(widget.latitude, widget.longitude),
          //           zoom: 14.0,
          //         ),
          //         markers: _markers,
          //         myLocationEnabled: false,
          //         compassEnabled: false,
          //         // Fix for iOS gesture conflicts
          //         // gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          //         //   Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          //         // },
          //       ),
          //       // ... rest of your UI (Send button)
          //     ],
          //   ),
          // ),

          BusinessLocationMapWidget(
            latitude: businessProfileDetails?.businessLocation?.lat ?? 0.0,
            longitude: businessProfileDetails?.businessLocation?.lon ?? 0.0,
            businessName: businessProfileDetails?.businessName ?? "",
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(label,
                  fontSize: 15, color: AppColors.mainTextColor)),
        ],
      ),
    );
  }

  Widget _buildHorizontalFoodList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.allFoodItems.length,
        itemBuilder: (context, index) {
          final item = controller.allFoodItems[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.product?.images?.firstOrNull ?? "",
                    height: 120,
                    width: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.secondaryTextColor)),
                          height: 120,
                          width: 160,
                          child: const Icon(Icons.fastfood)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomText(
                  item.product?.name ?? "",
                  fontWeight: FontWeight.bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.food_category,
                      imgColor: item.product?.dietaryType?.toLowerCase() == "non-veg"
                          ? AppColors.red00
                          : const Color(0xff008000),
                    ),
                    const SizedBox(width: 5),
                    CustomText(
                        "₹${item.variants?[0].price?.sellingPrice}",
                        fontWeight: FontWeight.w500),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCategories(List<FoodMenu> menus) {

    return Column(
      children: [
        SizedBox(height: SizeConfig.paddingXSL),
        CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                  'Our Menu',
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w600),

              SizedBox(
                height: SizeConfig.paddingXSL,
              ),

              menus.isNotEmpty ?
              MasonryGridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                itemCount: menus.length,
                itemBuilder: (context, index) {
                  var categoryItem = menus[index];
                  return CommonServiceCard(
                    service: categoryItem,
                    getName: (_categoryItem) => _categoryItem.name??'',
                    getIcon: (_categoryItem) => _categoryItem.image??'',
                    iconHeight: SizeConfig.size60,
                    boxShadow: [],
                    onTap: (_categoryItem) {

                      return Get.to(
                              ()=> MyFoodProductScreen(
                                foodMenu: _categoryItem,

                      ));

                      // return Get.toNamed(RouteHelper.getGroceryNestedCategoryWithInventoryScreenRoute(),
                      //   arguments: {
                      //     ApiKeys.userId: userId,
                      //     ApiKeys.argGroceryCategoryWithInventory: foodCategoryList,
                      //     ApiKeys.argArrGroceryCatKey: _categoryItem.key,
                      //     ApiKeys.argArrGroceryCatName: _categoryItem.name,
                      //   },
                      // );

                    },
                  );
                },
              )
                  :
              EmptyStateWidget(
                message: 'You don\'t have inventory yet, Want to create one?',
              ),

              SizedBox(
                height: SizeConfig.paddingXSL,
              ),

            ],
          ),
        ),
      ],
    );
  }
}
