import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/choose_deliivery_option_dialog.dart';
import 'package:BlueEra/features/common/Discover/view/widget/choose_food_option_dialog.dart';
import 'package:BlueEra/features/common/Discover/view/widget/grid_icon_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryCardWidget extends StatelessWidget {
  const GroceryCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        color: AppColors.whiteFC,
        borderRadius: BorderRadius.circular(0),
        padding: EdgeInsets.all(SizeConfig.size10),
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
              padding: const EdgeInsets.symmetric(horizontal:18.0),
              child: GridIconImageWidget(
                items: groceryOrFoodCategories,
                crossAxisCount: 3,
                getName: (item) => item.name,
                getIcon: (item) => item.icon,
                onTap: (item) {
                  if (item.slugId == AppConstants.grocery) {
                    // _chooseDeliveryOption(item.slugId);
                    Get.toNamed(
                      RouteHelper.getGroceryStoresScreenRoute(),
                    );
                  } else if (item.slugId == AppConstants.food) {
                    _chooseFoodOption();
                  } else {
                    Get.to(() => const HomeMadeFoodScreen());
                  }
                },
              ),
            )
          ],
        ));
  }

  void _chooseDeliveryOption(String slugId) {
    Get.dialog(
      ChooseDeliveryOptionDialog(),
      barrierDismissible: false,
    );
  }

  void _chooseFoodOption() {
    Get.dialog(
      const ChooseFoodOptionDialog(),
      barrierDismissible: false,
    );
  }
}
