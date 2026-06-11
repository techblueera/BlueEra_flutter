import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class FoodCategoryMenuScreen extends StatefulWidget {
  const FoodCategoryMenuScreen({super.key});

  @override
  State<FoodCategoryMenuScreen> createState() => _FoodCategoryMenuScreenState();
}

class _FoodCategoryMenuScreenState extends State<FoodCategoryMenuScreen> {
  // List mapped to your specific local assets
  final foodServiceController = getOrPut(() => FoodServiceController());

  @override
  void initState() {
    foodServiceController.getFoodNestedCategoryApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.foodFoodItemsLabel.tr,
      ),
      // Lazy CustomScrollView: the category grid is a SliverMasonryGrid that
      // builds ONLY the cards currently on screen. This makes the screen
      // crash-proof regardless of how many categories the API returns (the
      // food `categories/tree` endpoint can return ~1.7k roots of bad data).
      body: SafeArea(
        child: Obx(() {
          final status =
              foodServiceController.getFoodCategoryResponse.value.status;
          final categories = foodServiceController.foodNestedCateList;
          return CustomScrollView(
            slivers: [
              // Snap-search card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SizeConfig.size8,
                      SizeConfig.size15, SizeConfig.size8, 0),
                  child: CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title(AppStrings.foodUploadBulkProduct.tr),
                        SizedBox(height: SizeConfig.paddingXSL),
                        _snapSearchSuggestion(
                          onTap: () => Get.toNamed(
                            RouteHelper.getAddFoodSnapSearchScreenRoute(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Category title
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SizeConfig.size8,
                      SizeConfig.size12, SizeConfig.size8, SizeConfig.paddingXSL),
                  child: _title(AppStrings.category.tr),
                ),
              ),
              // Category grid (lazy) / states
              _categorySliver(status, categories),
              // Restaurant special + create-manually + bottom spacing
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SizeConfig.size8,
                      SizeConfig.size10, SizeConfig.size8, SizeConfig.size80),
                  child: Column(
                    children: [
                      _restaurantSpecialCard(),
                      SizedBox(height: SizeConfig.paddingXSL),
                      CustomBtn(
                        onTap: () {},
                        title: AppStrings.foodCreateManually.tr,
                        borderColor: AppColors.primaryColor,
                        bgColor:
                            AppColors.primaryColor.withValues(alpha: 0.1),
                        textColor: AppColors.primaryColor,
                        radius: 10.0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Category grid as a LAZY sliver (builds only visible cards) plus the
  /// loading / error / empty states.
  Widget _categorySliver(
      Status? status, List<GroceryNestedCategoryModel> categories) {
    if (status == Status.COMPLETE) {
      if (categories.isEmpty) {
        return SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: CustomText(AppStrings.noDataFound),
            ),
          ),
        );
      }
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childCount: categories.length,
          itemBuilder: (context, index) {
            final item = categories[index];
            return CommonServiceCard<GroceryNestedCategoryModel>(
              service: item,
              getName: (item) => item.name ?? '',
              getIcon: (item) => item.image ?? '',
              iconHeight: SizeConfig.size60,
              boxShadow: const [],
              onTap: (item) {
                foodServiceController.selectedFoodTypeID.value =
                    item.sId ?? "";
                Get.toNamed(
                  RouteHelper.getProductSelectionScreenRoute(),
                  arguments: {ApiKeys.argCategoryData: item},
                );
              },
            );
          },
        ),
      );
    } else if (status == Status.ERROR) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CustomText(AppStrings.somethingWentWrong),
          ),
        ),
      );
    }
    return SliverToBoxAdapter(child: buildCategoryGridSkeleton());
  }

  Widget _restaurantSpecialCard() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(AppStrings.foodRestaurantSpecial.tr),
          SizedBox(height: SizeConfig.paddingXSL),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: SizedBox(
              height: SizeConfig.size170,
              width: double.infinity,
              child: Stack(
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.foodDummyImage,
                    height: SizeConfig.size170,
                    width: double.infinity,
                    boxFix: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: SizeConfig.size80,
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(10.0)),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 14.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LocalAssets(
                              imagePath:
                                  "${AppConstants.baseFoodAssetsPath}restaurant_special.svg",
                              height: SizeConfig.size22,
                              width: SizeConfig.size22,
                            ),
                            SizedBox(width: SizeConfig.paddingXSL),
                            CustomText(
                              AppStrings.foodCreateRestaurantSpecial.tr,
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _title(String title){
    return CustomText(
        title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600
    );
  }

  Widget _snapSearchSuggestion({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SizeConfig.size8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LocalAssets(
                imagePath: AppIconAssets.cameraAddOutlineIcon,
                height: 18,
                width: 18,
                boxFix: BoxFit.scaleDown,
                imgColor: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    'Search products by photo',
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  CustomText(
                    'Upload a picture to find products instantly.',
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
