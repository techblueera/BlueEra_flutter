import 'dart:math';

import 'package:BlueEra/core/api/apiService/api_response.dart';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class OtherFoodStoreDetailsScreen extends StatefulWidget {
  final String visitBusinessId;

  const OtherFoodStoreDetailsScreen({super.key, required this.visitBusinessId});

  @override
  State<OtherFoodStoreDetailsScreen> createState() =>
      _OtherFoodStoreDetailsScreenState();
}

class _OtherFoodStoreDetailsScreenState
    extends State<OtherFoodStoreDetailsScreen> {
  final controller = getOrPut(() => RestaurantController());

  @override
  void initState() {
    super.initState();
    controller.fetchHomeData(businessId: widget.visitBusinessId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      backgroundColor: AppColors.appBackgroundColor,
      body: Obx(() {
        if (controller.foodHomeDataResponse.value.status == Status.INITIAL) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.restaurantData.value;
        if (data == null) {
          return Center(child: CustomText(AppStrings.noDataFound.tr));
        }

        return RefreshIndicator(
          onRefresh: () async {
            controller.fetchHomeData(businessId: widget.visitBusinessId);
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size15
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Profile Header (Read-Only)
                _foodHeaderWidget(data.businessProfileDetails),

                /// Food Selection (Horizontal List)
                if (controller.allFoodItems.isNotEmpty)
                  CustomFormCard(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(AppStrings.foodSelection.tr,
                            fontSize: 18, fontWeight: FontWeight.bold),
                        SizedBox(height: 10),
                        _buildHorizontalFoodList(),
                      ],
                    ),
                  ),

                /// Food Menu Categories
                if (data.foodMenu?.isNotEmpty??false)
                  _buildMenuCategories(data.foodMenu??[]),

                /// Gallery
                if (data.gallery?.isNotEmpty ?? false)
                  CommonCardWidget(
                    padding: 15,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CustomText(
                                AppStrings.gallery.tr,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildGallery(data.gallery??[], context),
                      ],
                    ),
                  ),


                SizedBox(height: 10.0),

                _buildContactNdMapCard(data.businessProfileDetails),

                SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _foodHeaderWidget(BusinessProfileDetails? details){
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner + Profile Image
            Container(
              height: 170,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner Image

                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      color: AppColors.greyLite, // Background color for the "empty" state
                      child: (details?.coverimage != null && details!.coverimage!.isNotEmpty)
                          ? Image.network(
                        details.coverimage!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildErrorPlaceholder();
                        },
                      )
                          : _buildErrorPlaceholder(), // Show icon if URL is null/empty
                    ),
                  ),

                  // Profile image overlapping banner bottom
                  Positioned(
                    left: 20,
                    top: 90, // makes it overlap smoothly
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.white, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.white,
                        child: details?.logo?.isNotEmpty == true
                            ? ClipOval(
                            child: NetWorkOcToAssets(imgUrl: details?.logo ?? "")
                        )
                            : LocalAssets(imagePath: AppIconAssets.user_out_line),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 5,
                    bottom: 10,
                    child: RatingBar.builder(
                      initialRating: 0,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 15, // Adjust size to match your UI
                      unratedColor: AppColors.secondaryTextColor, // Matches the grey outlines in your image
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => LocalAssets(
                        imagePath: AppIconAssets.star_rounded,
                        imgColor: Colors.amber, // Color when filled
                      ),
                      onRatingUpdate: (rating) {
                        print(rating);
                      },
                    ),
                  )

                ],
              ),
            ),

            // --- FORM SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  CustomText(details?.businessName,
                      fontSize: 18,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.bold),
                  const SizedBox(height: 10),
                  ExpandableText(
                    text: details?.businessDescription ?? AppStrings.na,
                    trimLines: 4,
                    isReadMoreNewLine: false,
                    expandMode: ExpandMode.dialog,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppConstants.OpenSans,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CommonRatingRow(
                    rating:
                    double.tryParse(details?.avg_rating.toString() ?? '0.0') ?? 0.0,
                    reviews: details?.total_ratings?.toInt() ?? 0,
                    distance: '${calculateDistanceKm(
                      LocationService.lat,
                      LocationService.lng,
                      details?.businessLocation?.lat?.toDouble() ?? 0.0,
                      details?.businessLocation?.lon?.toDouble() ?? 0.0,
                    ).toStringAsFixed(2)} Km Away',
                  ),

                  // const SizedBox(height: 10),
                  // CustomText(
                  //   "Monday – Friday: 9:00 AM – 6:00 PM",
                  //   color: AppColors.secondaryTextColor,
                  //   fontSize: SizeConfig.small,
                  //   fontWeight: FontWeight.w400,
                  // )
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        )

    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.cover,
        height: 130,
        width: double.infinity,
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
                              color: AppColors.secondaryTextColor),
                        ),
                        height: 120,
                        width: 160,
                        child: const Icon(Icons.fastfood),
                      ),
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
                      imgColor:
                          item.product?.dietaryType?.toLowerCase() == "non-veg"
                              ? AppColors.red00
                              : const Color(0xff008000),
                    ),
                    const SizedBox(width: 5),
                    CustomText(
                      "₹${item.price?.sellingPrice ?? ''}",
                      fontWeight: FontWeight.w500,
                    ),
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
              CustomText('Our Menu',
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w600),
              SizedBox(height: SizeConfig.paddingXSL),
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
                    getName: (_categoryItem) => _categoryItem.name ?? '',
                    getIcon: (_categoryItem) => _categoryItem.image ?? '',
                    iconHeight: SizeConfig.size60,
                    boxShadow: [],
                    onTap: (_categoryItem) {
                      // TODO: Navigate to customer food product listing
                    },
                  );
                },
              ),
              SizedBox(height: SizeConfig.paddingXSL),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGallery(
      List<FoodGallery> galleryList, BuildContext context) {
    List<String> allImages = [];
    for (var g in galleryList) {
      if (g.imageUrls != null) {
        allImages.addAll(g.imageUrls!);
      }
    }

    if (allImages.isEmpty) return const SizedBox();

    allImages.shuffle(Random());

    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(
        allImages.length > 10 ? 10 : allImages.length,
        (index) {
          int crossAxisCellCount = 2;
          num mainAxisCellCount = 2;

          if (index % 6 == 0 || index % 6 == 5) {
            crossAxisCellCount = 2;
            mainAxisCellCount = 3;
          } else if (index % 6 == 3) {
            crossAxisCellCount = 4;
            mainAxisCellCount = 2;
          } else {
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
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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

                if(businessProfileDetails?.userContactNo?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.phone_outline,
                      businessProfileDetails?.userContactNo?? "",
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

  // Widget _buildContactCard(FoodContact? profile) {
  //   return CommonCardWidget(
  //     padding: 15,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         CustomText(AppStrings.contactUs.tr,
  //             fontSize: 20, fontWeight: FontWeight.bold),
  //         const SizedBox(height: 20),
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: Colors.grey[200]!),
  //             borderRadius: BorderRadius.circular(15),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               if (controller
  //                       .restaurantData.value?.businessProfile?.logo?.isNotEmpty ??
  //                   false)
  //                 Container(
  //                   width: 100,
  //                   height: 100,
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     boxShadow: [
  //                       BoxShadow(color: Colors.black12, blurRadius: 10)
  //                     ],
  //                     image: DecorationImage(
  //                       image: NetworkImage(
  //                         controller.restaurantData.value?.businessProfile
  //                                 ?.logo ??
  //                             '',
  //                       ),
  //                       fit: BoxFit.cover,
  //                     ),
  //                   ),
  //                 ),
  //               const SizedBox(height: 10),
  //               CustomText(profile?.name,
  //                   fontSize: 20, fontWeight: FontWeight.bold),
  //               const SizedBox(height: 5),
  //               CustomText(
  //                 controller.restaurantData.value?.businessProfile
  //                     ?.businessDescription,
  //                 color: AppColors.secondaryTextColor,
  //                 fontSize: 14,
  //               ),
  //               const Divider(height: 30),
  //               _contactItem(AppIconAssets.website_click,
  //                   profile?.pageLink ?? "", AppColors.primaryColor),
  //               _contactItem(AppIconAssets.principal,
  //                   profile?.department ?? "", AppColors.secondaryTextColor),
  //               _contactItem(AppIconAssets.email, profile?.email ?? "",
  //                   AppColors.secondaryTextColor),
  //               _contactItem(AppIconAssets.phone_outline,
  //                   profile?.phone ?? "", AppColors.secondaryTextColor),
  //               _contactItem(
  //                   AppIconAssets.location_new,
  //                   profile?.location?.name ?? "",
  //                   AppColors.secondaryTextColor),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

}
