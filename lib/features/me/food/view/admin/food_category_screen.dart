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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size15
        ),
        child: SafeArea(
          child: Column(
            children: [

              CustomFormCard(
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

              Obx(() {
                if (foodServiceController.getFoodCategoryResponse.value.status ==
                    Status.COMPLETE) {
                  if (foodServiceController.foodNestedCateList.isNotEmpty) {
                    return CustomFormCard(
                      padding: EdgeInsets.all(SizeConfig.size10),
                      margin: EdgeInsets.only(top: SizeConfig.size10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _title(AppStrings.category.tr),
                          SizedBox(height: SizeConfig.paddingXSL),
                          MasonryGridView.count(
                            crossAxisCount: 3,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            itemCount: foodServiceController.foodNestedCateList.length,
                            shrinkWrap: true,
                            primary: false,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final item = foodServiceController.foodNestedCateList[index];
                              return CommonServiceCard<GroceryNestedCategoryModel>(
                                service: item,
                                getName: (item) => item.name??'',
                                  getIcon: (item) =>  item.image??'',
                                // getIcon: (item) => "${AppConstants.baseFoodAssetsPath}${item.key ?? " "}.svg",
                                iconHeight: SizeConfig.size60,
                                boxShadow: [],
                                onTap: (item) {
                                  foodServiceController.selectedFoodTypeID.value =
                                      item.sId ?? "";

                                  // Action for item tap
                                  Get.toNamed(RouteHelper.getProductSelectionScreenRoute(),
                                  arguments: {
                                    ApiKeys.argCategoryData: item
                                  });
                                },
                              );

                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: CustomText(AppStrings.noDataFound),
                        ));
                  }
                } else if (foodServiceController.getFoodCategoryResponse.value.status ==
                    Status.ERROR) {
                  return Center(
                      child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: CustomText(AppStrings.somethingWentWrong),
                  ));
                }
                return buildCategoryGridSkeleton();
              }),

              CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  margin: EdgeInsets.only(top: SizeConfig.size10),
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
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0))
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
                                      borderRadius: BorderRadius.circular(10.0)
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        LocalAssets(
                                            imagePath: "${AppConstants.baseFoodAssetsPath}restaurant_special.svg",
                                            height: SizeConfig.size22,
                                            width: SizeConfig.size22,
                                        ),
                                        SizedBox(width: SizeConfig.paddingXSL),
                                        CustomText(
                                            AppStrings.foodCreateRestaurantSpecial.tr,
                                            fontSize: SizeConfig.small,
                                            color: AppColors.secondaryTextColor,
                                            fontWeight: FontWeight.w400
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
                  )
              ),

              SizedBox(height: SizeConfig.paddingXSL),

              CustomBtn(
                  onTap: (){},
                  title: AppStrings.foodCreateManually.tr,
                  borderColor: AppColors.primaryColor,
                  bgColor: AppColors.primaryColor.withValues(alpha: 0.1),
                  textColor: AppColors.primaryColor,
                  radius: 10.0,
              ),

              SizedBox(height: SizeConfig.size80),

            ],
          ),
        ),
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
