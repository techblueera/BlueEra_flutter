import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
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

              // ── Snap-search suggestion (conditional) ─────────────────
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
                      _snapSearchSuggestion(
                        onTap: () => Get.toNamed(
                          RouteHelper.getAddGrocerySnapSearchScreenRoute(),
                        ),
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