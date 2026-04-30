import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_data.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class GrocerySuperCategoryScreen extends StatelessWidget {
  final bool isAvailBulkUpload;
  GrocerySuperCategoryScreen({super.key, required this.isAvailBulkUpload});

  final controller = getOrPut(() => GroceryController());

  @override
  Widget build(BuildContext context) {
    controller.fetchGroceryNestedCategory();

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.addProducts,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: CustomBtn(
            height: SizeConfig.size35,
            width: SizeConfig.size70,
            onTap: () {},
            bgColor: AppColors.white,
            borderColor: AppColors.primaryColor,
            radius: 10.0,
            title: AppStrings.groceryViewTutorial.tr,
            textColor: AppColors.primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size15,
        ),
        child: SafeArea(
          child: Column(
            children: [

              // ── Bulk Upload Card (conditional) ──────────────────────────
              if (isAvailBulkUpload) ...[
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.groceryViewUploadBulkProducts.tr,
                        fontSize: SizeConfig.large,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),
                      MasonryGridView.count(
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.grocerySnapSearchConfig.length,
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          var item = controller.grocerySnapSearchConfig[index];
                          return InkWell(
                            onTap: () => Get.toNamed(
                                RouteHelper.getAddGrocerySnapSearchScreenRoute()),
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
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.paddingXSL),
              ],

              // ── Category Grid (dynamic from API) ────────────────────────
              CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.groceryViewCategory.tr,
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),

                    Obx(() {
                      // ── Loading state ──
                      if (controller.fetchNestedGroceryCategoryResponse.value.status == Status.INITIAL) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      // ── Error state ──
                      if (controller.fetchNestedGroceryCategoryResponse.value ==
                          Status.ERROR) {
                        return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              child: CustomText(AppStrings.somethingWentWrong),
                            ));
                      }

                      // ── Empty state ──
                      if (controller.grocerySuperCategoryList.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(AppStrings.groceryViewNoCategoriesFound.tr),
                          ),
                        );
                      }

                      // ── Populated grid ──
                      return MasonryGridView.count(
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.grocerySuperCategoryList.length,
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final category =
                          controller.grocerySuperCategoryList[index];

                          return CommonServiceCard<GroceryNestedCategoryModel>(
                            service: category,
                            getName: (item) => item.name ?? '',
                            getIcon: (item) => item.image ?? '',
                            iconHeight: SizeConfig.size60,
                            boxShadow: [],
                            onTap: (item) {
                              Get.toNamed(
                                RouteHelper.getGroceryNestedCategoryScreenRoute(),
                                arguments: {
                                  // ApiKeys.argMyGrocery: true,
                                  ApiKeys.argArrGrocerySuperCategory:
                                  controller.grocerySuperCategoryList
                                      .toList(),
                                  ApiKeys.argArrGroceryCatKey: item.key,
                                  ApiKeys.argArrGroceryCatName: item.name,
                                },
                              );
                            },
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}