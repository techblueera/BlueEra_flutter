import 'dart:ui';

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
import 'package:BlueEra/features/me/grocery/controller/grocery_rider_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';


class AddGroceryViaRiderCategoryScreen extends StatefulWidget {
  const AddGroceryViaRiderCategoryScreen({super.key});

  @override
  State<AddGroceryViaRiderCategoryScreen> createState() =>
      _AddGroceryViaRiderCategoryScreenState();
}

class _AddGroceryViaRiderCategoryScreenState
    extends State<AddGroceryViaRiderCategoryScreen> {
  final groceryController = getOrPut(() => GroceryController());
  final consumerController = getOrPut(() => GroceryRiderConsumerController());

  @override
  void initState() {
    groceryController.fetchGroceryNestedCategory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: SizeConfig.size15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBulkUploadSection(),
            SizedBox(height: SizeConfig.paddingXSL),
            _buildCategory(),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkUploadSection() {
   return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Bulk Upload Shop Product Photos',
            fontSize: SizeConfig.large,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          MasonryGridView.count(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: consumerController.grocerySnapSearchConfig.length,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              var item = consumerController.grocerySnapSearchConfig[index];
              return InkWell(
                onTap: () => Get.toNamed(
                    RouteHelper.getGroceryRiderSnapSearchScreenRoute()),
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
    );
  }

  Widget _buildCategory(){
    return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.paddingXSL),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomText(
                  AppStrings.groceryNdStationary,
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(width: SizeConfig.paddingXSL),
                _buildPaymentMode(AppStrings.cashOnDelivery),
              ],
            ),

            SizedBox(height: SizeConfig.paddingXSL),

            // ── Category Grid ────────────────────────────────────────────
            Obx(() {
              final status = groceryController
                  .fetchNestedGroceryCategoryResponse.value.status;

              if (status == Status.COMPLETE) {
                if (groceryController.grocerySuperCategoryList.isNotEmpty) {
                  return MasonryGridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount:
                    groceryController.grocerySuperCategoryList.length,
                    shrinkWrap: true,
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item =
                      groceryController.grocerySuperCategoryList[index];
                      return CommonServiceCard<GroceryNestedCategoryModel>(
                        service: item,
                        getName: (item) => item.name ?? '',
                        getIcon: (item) => item.image ?? '',
                        iconHeight: SizeConfig.size60,
                        boxShadow: [],
                        onTap: (_categoryItem) {
                          Get.toNamed(
                            RouteHelper.getAllGroceryCategorizeProductsScreenRoute(),
                            arguments: {
                              ApiKeys.argCategories: _categoryItem.children,
                            },
                          );
                        },
                      );
                    },
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: CustomText(AppStrings.noDataFound),
                  ),
                );
              }

              if (status == Status.ERROR) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: CustomText(AppStrings.somethingWentWrong),
                  ),
                );
              }

              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }),
          ],
        )
    );
  }

  Widget _buildPaymentMode(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: AppColors.yellowBC.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.extraSmall,
        color: AppColors.yellowBC,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}