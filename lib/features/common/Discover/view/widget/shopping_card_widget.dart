import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/view/new_store/all_business_products_screen.dart';
import 'package:BlueEra/features/common/store/view/new_store/products_store_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShoppingCardWidget extends StatefulWidget {
  const ShoppingCardWidget({super.key});

  @override
  State<ShoppingCardWidget> createState() => _ShoppingCardWidgetState();
}

class _ShoppingCardWidgetState extends State<ShoppingCardWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final allCategories = Get.find<AuthController>().businessOnboardingProductsCategories;
    final showMoreButton = allCategories.length > 9;
    final displayCategories = _showAll ? allCategories : allCategories.take(9).toList();

    return CustomFormCard(
        color: AppColors.white,
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                titleWidget(AppStrings.shopping.tr),
                SizedBox(
                  width: SizeConfig.size8,
                ),
                if (showMoreButton)
                  ViewAllButton(
                    onTap: () => setState(() => _showAll = !_showAll),
                    label: _showAll
                        ? AppStrings.showLess.tr
                        : AppStrings.showMore.tr,
                  ),
              ],
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: LayoutBuilder(
                  builder: (context, constraints) {
                const double spacing = 8;
                const int columns = 3;
                final double itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: displayCategories.map((categoryItem) {
                    return SizedBox(
                      width: itemWidth,
                      child: CommonServiceCard(
                        service: categoryItem,
                        getName: (item) => item.name ?? '',
                        getIcon: (item) => getProductCategoryIcon(item.tagId),
                        onTap: (item) {

                          Get.to(() => ProductsStoreScreen(
                            productCategoryName: item.name,
                            productCategory: item.tagId,
                          ));

                          // _showShoppingOptionDialog(
                          //   context,
                          //   categoryData: item
                          //   );
                        },
                      ),
                    );
                  }).toList(),
                );
              }),
            )
          ],
        ));
  }

  void _showShoppingOptionDialog(BuildContext context, {CategoryData? categoryData}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.greyE5, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.howWouldYouLikeToShop.tr,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Option 1: Browse Products
              _buildOptionTile(
                icon: AppIconAssets.productCartIcon,
                title: AppStrings.browseProducts.tr,
                subtitle: AppStrings.browseProductsSubtitle.tr,
                onTap: () {
                  Get.to(() => AllBusinessProductsScreen(
                    productCategoryName: categoryData?.name,
                    productCategory: categoryData?.tagId,
                  ));
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Shop Via Store
              _buildOptionTile(
                icon: AppIconAssets.staggeredIcon,
                title: AppStrings.shopViaStore.tr,
                subtitle: AppStrings.shopViaStoreSubtitle.tr,
                onTap: () {
                  Get.to(() => ProductsStoreScreen(
                    productCategoryName: categoryData?.name,
                    productCategory: categoryData?.tagId,
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.whiteFE,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.greyE5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: LocalAssets(
                  imagePath: icon,
                  height: 24,
                  width: 24,
                  imgColor: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    const SizedBox(height: 3),
                    CustomText(
                      subtitle,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
