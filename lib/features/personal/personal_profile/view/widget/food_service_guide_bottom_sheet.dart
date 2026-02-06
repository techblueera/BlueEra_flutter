import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class FoodServiceGuideBottomSheet extends StatefulWidget {
  FoodServiceGuideBottomSheet({Key? key}) : super(key: key);

  @override
  State<FoodServiceGuideBottomSheet> createState() => _FoodServiceGuideBottomSheetState();
}

class _FoodServiceGuideBottomSheetState extends State<FoodServiceGuideBottomSheet> {
  int? selectedIndex;
  OnboardingCategoryModel? selectedService;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
            top: 5
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  AppStrings.homeMadeFoodItems,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: SizeConfig.size16),
            HorizontalVideoPlayer(),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              '${AppStrings.homeMadeFoodItems.tr} ${AppStrings.earnWithHomeMadeSubtitle.tr} ',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              AppStrings.selectFoodType,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size16),

            // 3-column grid
            Flexible(
              child: MasonryGridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: homeMadeFoodCategories.length,
                itemBuilder: (_, i) => CommonServiceCard(
                  service: homeMadeFoodCategories[i],
                  getName: (item) => item.name,
                  getIcon: (item) => item.icon,
                  isSelected: selectedIndex == i,
                  spacing: 8.0,
                  onTap: (item) {
                    setState(() {
                      if (selectedIndex == i) {
                        selectedIndex = null;
                        selectedService = null;
                      } else {
                        selectedIndex = i;
                        selectedService = item;
                      }
                    });
                  },
                ),
              ),
            ),

            CustomBtn(
              height: SizeConfig.size40,
              title: AppStrings.startListingNow,
              onTap: () {
                if (selectedService == null) {
                  commonSnackBar(message: AppStrings.selectFoodTypeMessage);

                  return;
                }
                Get.back();
                Get.toNamed(
                  RouteHelper.getFoodUploadScreenRoute(),
                  arguments: {
                    ApiKeys.providerType: ProviderType.user,
                    ApiKeys.serviceSubType: EarnServiceTypes.homeMadeFood,
                    ApiKeys.category: selectedService?.slugId,
                  },
                );
         /*       Get.offNamedUntil(
                  RouteHelper.getFoodUploadScreenRoute(),
                  ModalRoute.withName(RouteHelper.getEarnWithBlueEraNewScreenRoute()),
                  arguments: {
                    ApiKeys.providerType: ProductServiceProviderType.user,
                    ApiKeys.serviceSubType: EarnWithBlueEraServiceTypes.homeMadeFood,
                    ApiKeys.category: selectedService?.slugId,
                  },
                );*/
              },
              bgColor: AppColors.primaryColor,
              textColor: AppColors.white,
              radius: 10.0,
            ),

            SizedBox(height: SizeConfig.size16),

          ],
        ),
      ),
    );
  }
}

