import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/choose_deliivery_option_dialog.dart';
import 'package:BlueEra/features/common/Discover/view/widget/grid_icon_image_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryFoodCardWidget extends StatelessWidget {
  const GroceryFoodCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        color: AppColors.whiteFC,
        borderRadius: BorderRadius.circular(0),
        padding: EdgeInsets.all(SizeConfig.size10),
        child: InkWell(
          onTap: () => chooseDeliveryOption(),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: titleWidget("Grocery & Food"),
                  ),
                  SizedBox(width: SizeConfig.paddingXSL),
                  ViewAllButton(
                    onTap: () {},
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.paddingXSL),
              GridIconImageWidget(
                items: [
                  ...GroceryData.grocerySuperCategories.take(3).toList(),
                ],
                crossAxisCount: 3,
                getName: (item) => item.name,
                getIcon: (item) => item.icon,
                onTap: (item) {
                  if (item.slugId == "HOME_MADE_FOOD") {
                    Get.to(() => HomeMadeFoodScreen());
                  } else {
                    chooseDeliveryOption();
                  }
                },
              )
            ],
          ),
        ));
  }

  void chooseDeliveryOption() {
    Get.dialog(
      ChooseDeliveryOptionDialog(),
      barrierDismissible: false,
    );
  }
}
