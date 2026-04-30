import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/models/product_consumer_nested_category_response.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/me/product/widget/create_own_product_via_ai_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ProductSuperCategoryScreen extends StatelessWidget {
  final String? ownerID;
  final ProviderType? providerType;

  ProductSuperCategoryScreen({
    super.key,
    this.ownerID,
    this.providerType,
  });

  final controller = getOrPut(() => ProductController());

  @override
  Widget build(BuildContext context) {
    controller.fetchProductsNestedCategory();
    if (ownerID != null) controller.ownerID = ownerID;
    if (providerType != null) controller.ownerProviderType = providerType;

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.addProducts,
        buildCustomActionWidget: () => CreateOwnProductViaAiWidget(
          providerType: ProviderType.business,
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

              // ── Two Options: Photo Upload & Add by Category ────────
              CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Add Products',
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
                    MasonryGridView.count(
                      shrinkWrap: true,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.productSnapSearchConfig.length,
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        var item = controller.productSnapSearchConfig[index];
                        return InkWell(
                          onTap: () => Get.toNamed(
                              RouteHelper.getAddProductTextOrSnapScreenRoute(),
                              arguments: {
                                ApiKeys.id: controller.ownerID,
                                ApiKeys.providerType: controller.ownerProviderType,
                            },
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              height: SizeConfig.size180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.greyE5),
                                image: DecorationImage(
                                  image: AssetImage(item['image']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 2, sigmaY: 2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: AppColors.black
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            padding: EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              color: AppColors.white
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.white
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
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
                                                ),
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

              // ── Category Grid (dynamic from API) ──────────────────
              CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Category',
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),

                    Obx(() {
                      // ── Loading state ──
                      if (
                      controller.nestedProductCategoryResponse.value.status == Status.INITIAL
                      ) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      // ── Empty state ──
                      if (controller.productsNestedCategoryList.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text('No categories found.'),
                          ),
                        );
                      }

                      // ── Populated grid ──
                      return MasonryGridView.count(
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.productsNestedCategoryList.length,
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final category = controller.productsNestedCategoryList[index];

                          return CommonServiceCard<ProductNestedCategoryResponse>(
                            service: category,
                            getName: (item) => item.name ?? '',
                            getIcon: (item) => '',
                            iconHeight: SizeConfig.size60,
                            boxShadow: [],
                            onTap: (item) {
                              Get.toNamed(
                                RouteHelper
                                    .getProductNestedCategoryScreenRoute(),
                                arguments: {
                                  ApiKeys.argArrProductSuperCategory: controller.productsNestedCategoryList.toList(),
                                  ApiKeys.argArrProductCatId: item.sId,
                                  ApiKeys.argArrProductCatName: item.name,
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
