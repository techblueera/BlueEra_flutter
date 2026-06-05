import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/me/product/view/customer/products_store_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
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
                  children: displayCategories.map((c) {
                    return SizedBox(
                      width: itemWidth,
                      child: CommonServiceCard(
                        service: c,
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


}
