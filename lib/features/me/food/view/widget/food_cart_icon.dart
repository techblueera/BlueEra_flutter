import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';

class FoodCartIconButton extends StatelessWidget {
  const FoodCartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FoodCustomerController>();

    return Obx(() {
      // Logic for Empty Cart (Show Search)
      if (controller.selectedVariantsMap.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: Icon(Icons.search, color: AppColors.mainTextColor),
        );
      }

      // Logic for Items in Cart (Show Badge)
      return InkWell(
        onTap: () => Get.toNamed(RouteHelper.getFoodReviewSelectionScreenRoute()),
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              LocalAssets(
                imagePath: AppIconAssets.cartIcon,
                height: SizeConfig.size24,
                width: SizeConfig.size24,
              ),
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  height: SizeConfig.size16,
                  width: SizeConfig.size16,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: CustomText(
                        '${controller.totalVariantsCount}',
                        fontSize: 10,
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}