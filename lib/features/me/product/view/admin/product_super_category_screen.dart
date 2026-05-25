import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/create_own_product_via_ai_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
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

              // ── Snap-search suggestion ─────────────────────────────
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
                    _snapSearchSuggestion(
                      onTap: () => Get.toNamed(
                        RouteHelper.getAddProductTextOrSnapScreenRoute(),
                        arguments: {
                          ApiKeys.id: controller.ownerID,
                          ApiKeys.providerType: controller.ownerProviderType,
                        },
                      ),
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
                      if (controller.productsNestedCategoryList.isNotEmpty) {
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
                            getIcon: (item) => item.image ?? '',
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
                      } else if (controller.nestedProductCategoryResponse.value.status == Status.ERROR) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: CustomText(AppStrings.somethingWentWrong),
                          ),
                        );
                      } else if (controller.nestedProductCategoryResponse.value.status == Status.COMPLETE) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CustomText('No categories found.'),
                          ),
                        );
                      }
                      return buildCategoryGridSkeleton();
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
