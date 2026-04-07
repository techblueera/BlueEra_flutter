import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/view/quick_food_search_screen.dart';
import 'package:BlueEra/features/me/food/view/restaurant_near_me_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChooseFoodOptionDialog extends StatelessWidget {
  const ChooseFoodOptionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greenShade, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    AppStrings.howWouldYouLikeToFindFood.tr,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
                CloseButton(),
              ],
            ),
            const SizedBox(height: 10),
            _buildOption(
              icon: AppIconAssets.fastFoodQuickServiceIcon,
              title: AppStrings.quickFoodSearch.tr,
              subtitle: AppStrings.quickFoodSearchSubtitle.tr,
              onTap: () {
                Get.back();
                Get.to(() => const QuickFoodSearchScreen());
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: AppIconAssets.restaurantIcon,
              title: AppStrings.searchViaRestaurant.tr,
              subtitle: AppStrings.searchViaRestaurantSubtitle.tr,
              onTap: () {
                Get.back();
                Get.to(() => const RestaurantNearMeScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.whiteFE,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: AppColors.greyE5, width: 1.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: LocalAssets(imagePath: icon, boxFix: BoxFit.contain),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      subtitle,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
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
