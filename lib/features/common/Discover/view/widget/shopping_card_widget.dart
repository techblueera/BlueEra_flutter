import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/product_local_market_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ShoppingCardWidget extends StatelessWidget {
  const ShoppingCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        color: AppColors.whiteFC,
        padding: EdgeInsets.all(SizeConfig.size10),
        borderRadius: BorderRadius.circular(0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: titleWidget(AppStrings.shopping.tr),
                ),
                SizedBox(
                  width: SizeConfig.size8,
                ),
                ViewAllButton(
                  onTap: () {
                    Get.to(() => ProductLocalMarketScreen(
                          businessProductsCategories:
                              businessProductsCategories,
                          businessProductStoreCategories:
                              businessProductStoreCategories,
                        ));
                  },
                ),
              ],
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            MasonryGridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              padding: EdgeInsets.zero,
              primary: false,
              shrinkWrap: true,
              itemCount: businessProductsCategories.take(9).length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var categoryItem = businessProductsCategories[index];
                return CommonServiceCard(
                  service: categoryItem,
                  getName: (item) => item.name,
                  getIcon: (item) => item.icon ?? '',
                  onTap: (item) {
                    Get.to(() => ProductLocalMarketScreen(
                          businessProductsCategories:
                              businessProductsCategories,
                          businessProductStoreCategories:
                              businessProductStoreCategories,
                        ));
                  },
                );
              },
            )
          ],
        ));
  }
}
