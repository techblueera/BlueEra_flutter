import 'dart:math';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_home_profile_header.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_cart_icon.dart';
import 'package:get/get.dart';
import '../../../../core/api/model/new_food_home_res_model.dart';

class DiscoverFoodHomeScreen extends StatelessWidget {
  final FoodData foodData;

  const DiscoverFoodHomeScreen({super.key, required this.foodData});

  @override
  Widget build(BuildContext context) {
    final data = foodData;

    return Scaffold(
      appBar: CommonBackAppBar(
        title: data.businessProfile?.businessName,
        buildCustomActionWidget: () => const DiscoverCartIcon(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// FOOD HOTEL PROFILE HEADER
            CommonCardWidget(
              cardMargin: SizeConfig.size10,
              padding: 0,
              child: FoodHomeProfileHeader(
                details: data.businessProfile,
                controller: Get.find<ViewBusinessDetailsController>(),
              ),
            ),

            /// FOOD SELECTION (Horizontal Scroll)
            if (data.foodMenu?.isNotEmpty ?? false)
              CommonCardWidget(
                cardMargin: SizeConfig.size10,
                padding: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppStrings.foodSelection.tr),
                    SizedBox(height: SizeConfig.size8),
                    _buildHorizontalFoodList(),
                    SizedBox(height: SizeConfig.size10),
                  ],
                ),
              ),

            /// FOOD MENU CATEGORIES
            if (data.foodMenu?.isNotEmpty ?? false)
              CommonCardWidget(
                cardMargin: SizeConfig.size10,
                padding: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppStrings.ourMenu.tr),
                    _buildMenuCategories(data.foodMenu ?? []),
                    SizedBox(height: SizeConfig.size8),
                  ],
                ),
              ),

            /// GALLERY
            if (data.gallery?.isNotEmpty ?? false)
              CommonCardWidget(
                padding: SizeConfig.size15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(AppStrings.gallery.tr,
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.bold),
                    SizedBox(height: SizeConfig.size12),
                    _buildGallery(data.gallery ?? [], context),
                  ],
                ),
              ),

            /// CONTACT US
            _buildContactCard(data.contact),

            /// MAP / LOCATION
            if (data.contact != null)
              BusinessLocationWidget(
                locationText: data.contact?.location?.name ?? "",
                latitude: double.parse(
                    data.contact?.location?.coordinates?[0].toString() ??
                        "0.0"),
                longitude: double.parse(
                    data.contact?.location?.coordinates?[1].toString() ??
                        "0.0"),
                businessName: data.contact?.name ?? "",
                padding: SizeConfig.size10,
                isTitleShow: true,
              ),

            SizedBox(height: SizeConfig.size100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.size15,
        right: SizeConfig.size15,
        top: SizeConfig.size12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(title,
              fontSize: SizeConfig.large18, fontWeight: FontWeight.bold),
          SizedBox(height: SizeConfig.size6),
          Container(
            width: SizeConfig.size40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFoodList() {
    return SizedBox(
      height: SizeConfig.size150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
        itemCount: foodData.foodMenu?.length,
        itemBuilder: (context, index) {
          final item = foodData.foodMenu?[index];
          return Container(
            width: SizeConfig.size140,
            margin: EdgeInsets.only(right: SizeConfig.size12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SizeConfig.size12),
              border: Border.all(color: AppColors.whiteE5),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(SizeConfig.size12),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: LocalAssets(
                        imagePath:
                            'assets/category/food_home/${item?.key}.png',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size8,
                    vertical: SizeConfig.size10,
                  ),
                  child: CustomText(
                    item?.name ?? "",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.medium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCategories(List<FoodMenu> menus) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size15,
        vertical: SizeConfig.size10,
      ),
      itemCount: menus.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: SizeConfig.size10,
        mainAxisSpacing: SizeConfig.size10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final category = menus[index];

        return InkWell(
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SizeConfig.size12),
              border: Border.all(color: AppColors.whiteE5),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: LocalAssets(
                      imagePath:
                          'assets/category/food_home/${category.key}.png',
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: SizeConfig.size6,
                    right: SizeConfig.size6,
                    bottom: SizeConfig.size10,
                  ),
                  child: CustomText(
                    category.name,
                    maxLines: 2,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGallery(List<Gallery> galleryList, BuildContext context) {
    List<String> allImages = [];
    for (var g in galleryList) {
      if (g.imageUrls != null) {
        allImages.addAll(g.imageUrls!);
      }
    }

    if (allImages.isEmpty) return const SizedBox();

    allImages.shuffle(Random());
    final displayCount = allImages.length > 10 ? 10 : allImages.length;

    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: SizeConfig.size8,
      crossAxisSpacing: SizeConfig.size8,
      children: List.generate(displayCount, (index) {
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
              borderRadius: BorderRadius.circular(SizeConfig.size12),
              child: Image.network(
                allImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.whiteF3,
                  child: Icon(Icons.broken_image,
                      color: AppColors.secondaryTextColor),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContactCard(Contact? profile) {
    return CommonCardWidget(
      padding: SizeConfig.size15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(AppStrings.contactUs.tr,
              fontSize: SizeConfig.large18, fontWeight: FontWeight.bold),
          SizedBox(height: SizeConfig.size16),
          Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.whiteE5),
              borderRadius: BorderRadius.circular(SizeConfig.size15),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (foodData.businessProfile?.logo?.isNotEmpty ?? false)
                  Row(
                    children: [
                      Container(
                        width: SizeConfig.size80,
                        height: SizeConfig.size80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ],
                          image: DecorationImage(
                            image: NetworkImage(
                                foodData.businessProfile?.logo ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(profile?.name,
                                fontSize: SizeConfig.large18,
                                fontWeight: FontWeight.bold),
                            if (foodData
                                    .businessProfile?.businessDescription !=
                                null)
                              Padding(
                                padding:
                                    EdgeInsets.only(top: SizeConfig.size4),
                                child: CustomText(
                                  foodData
                                      .businessProfile?.businessDescription,
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.medium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (foodData.businessProfile?.logo?.isNotEmpty ?? false)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                    child: const Divider(height: 1),
                  ),
                if (!(foodData.businessProfile?.logo?.isNotEmpty ?? false)) ...[
                  CustomText(profile?.name,
                      fontSize: SizeConfig.large18,
                      fontWeight: FontWeight.bold),
                  if (foodData.businessProfile?.businessDescription != null)
                    Padding(
                      padding: EdgeInsets.only(top: SizeConfig.size4),
                      child: CustomText(
                        foodData.businessProfile?.businessDescription,
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.medium,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                    child: const Divider(height: 1),
                  ),
                ],
                _contactItem(AppIconAssets.website_click,
                    profile?.pageLink ?? "", AppColors.primaryColor),
                _contactItem(AppIconAssets.principal,
                    profile?.department ?? "", AppColors.secondaryTextColor),
                _contactItem(AppIconAssets.email, profile?.email ?? "",
                    AppColors.secondaryTextColor),
                _contactItem(AppIconAssets.phone_outline,
                    profile?.phone ?? "", AppColors.secondaryTextColor),
                _contactItem(
                    AppIconAssets.location_new,
                    profile?.location?.name ?? "",
                    AppColors.secondaryTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    if (label.isEmpty) return const SizedBox();
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size12),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: iconColor,
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: CustomText(label,
                fontSize: SizeConfig.medium15,
                color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }
}
