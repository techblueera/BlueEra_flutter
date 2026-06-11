import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_category_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/grid_icon_image_widget.dart';
import 'package:BlueEra/features/me/food/view/customer/restaurant_near_me_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryCardWidget extends StatelessWidget {
  const GroceryCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        color: AppColors.white,
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                titleWidget(AppStrings.groceryAndFood.tr),
              ],
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridIconImageWidget(
                items: groceryOrFoodCategories,
                crossAxisCount: 3,
                getName: (item) => item.name.tr,
                getIcon: (item) => item.icon,
                onTap: (item) {
                  if (item.slugId == AppConstants.grocery) {
                    // _chooseDeliveryOption(item.slugId);
                    Get.toNamed(
                      RouteHelper.getGroceryStoresScreenRoute(),
                    );
                  } else if (item.slugId == AppConstants.food) {
                    Get.to(() => const RestaurantNearMeScreen());
                    // _chooseFoodOption();
                  } else {
                    Get.to(() => const HmfCategoryDiscoverScreen());
                    // Get.dialog(
                    //   const ChooseHomeMadeFoodOptionDialog(),
                    //   barrierDismissible: false,
                    // );
                  }
                },
              ),
            )
          ],
        ));
  }


}
