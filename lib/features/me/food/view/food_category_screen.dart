import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
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
                      CustomText(
                          AppStrings.foodUploadBulkProduct.tr,
                          fontSize: SizeConfig.large,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),
                      MasonryGridView.count(
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: foodServiceController.foodSnapSearchPhotos.length,
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          var item = foodServiceController.foodSnapSearchPhotos[index];
                          return InkWell(
                            onTap: ()=> Get.toNamed(RouteHelper.getAddFoodSnapSearchScreenRoute()),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Container(
                                height: SizeConfig.size180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.greyE5),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        item['image']!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                ),
                                child: Stack(
                                  children: [

                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: AppColors.black.withValues(alpha: 0.6)
                                              )
                                          ),
                                        ),
                                      ),
                                    ),

                                    Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                            child: Container(
                                              padding: EdgeInsets.all(10.0),
                                              decoration: BoxDecoration(
                                                color: AppColors.white.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: AppColors.white.withValues(alpha: 0.1
                                                    )
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  LocalAssets(
                                                    imagePath: item['icon']!,
                                                    height: 18,
                                                    width: 18,
                                                    boxFix: BoxFit.scaleDown,
                                                    imgColor: AppColors.white,
                                                  ),
                                                  SizedBox(width: 6),
                                                  CustomText(
                                                    item['title']!,
                                                    fontSize: SizeConfig.small,
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.w400,
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  )
              ),

              Obx(() {
                if (foodServiceController.getFoodCategoryResponse.value.status ==
                    Status.COMPLETE) {
                  if (foodServiceController.foodNestedCateList.isNotEmpty) {
                    return MasonryGridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                    );
                  } else {
                    return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: CustomText(AppStrings.noDataFound),
                        ));
                  }
                } else if (foodServiceController.getFoodCategoryResponse.value ==
                    Status.ERROR) {
                  return Center(
                      child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: CustomText(AppStrings.somethingWentWrong),
                  ));
                }
                return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: CircularProgressIndicator(),
                    ));
              }),

              CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                          AppStrings.foodRestaurantSpecial.tr,
                          fontSize: SizeConfig.large,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600
                      ),
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
}
