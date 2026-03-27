import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/all_food_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class RestaurantNearMeCardWidget extends StatelessWidget {
  const RestaurantNearMeCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return  CustomFormCard(
      color: AppColors.whiteFC,
      borderRadius: BorderRadius.circular(0),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget(AppStrings.restaurantNearby),
              SizedBox(
                width: SizeConfig.size8,
              ),
              ViewAllButton(
                onTap: () {
                  Get.to(AllFoodServiceScreen(
                    professionalConsultantCategories: businessOnboardingFoodsCategories,
                    selectedProfessionConsultantData: businessOnboardingFoodsCategories.first,
                  ));
                },
              ),                    ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:18.0),
            child: SizedBox(
              height: 140, // Adjust this height based on your CommonServiceCard design
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size6),
                itemCount: businessOnboardingFoodsCategories.take(6).length,
                // Using a physics that feels natural on mobile
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  var categoryItem = businessOnboardingFoodsCategories[index];

                  return Padding(
                    padding: EdgeInsets.only(right: 6), // Matches your previous margin: 6
                    child: SizedBox(
                      width: 120, // Horizontal lists need a fixed width for children
                      child: AspectRatio(
                        aspectRatio: 1.0, // Adjusted for a more square look like the design
                        child: Container(
                          margin: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20), // Increased for smoother look
                            border: Border.all(color: categoryItem.colorCode??Colors.white, width: 1.0),
                          ),
                          // Use ClipRRect so the children don't bleed over the rounded border
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Column(
                              children: [
                                // 1. Top Section: Icon with soft background
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    width: double.infinity,
                                    color: categoryItem.colorCode, // The soft blue tint from your image
                                    child: LocalAssets(imagePath: categoryItem.icon ?? ""),
                                  ),
                                ),

                                // 2. Bottom Section: Text with solid background
                                Container(
                                  width: double.infinity,
                                  color: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomText(
                                        categoryItem.name,
                                        textAlign: TextAlign.center,
                                        color: AppColors.mainTextColor, // White text looks better on Red
                                        fontWeight: FontWeight.w500,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      /*child: CommonServiceCard(
                        service: categoryItem,color: categoryItem.colorCode,
                        getName: (item) => item.name,
                        getIcon: (item) => item.icon ?? '',
                        iconHeight: SizeConfig.size80,
                        onTap: (item) {
                          Get.to(AllFoodServiceScreen(
                            professionalConsultantCategories: businessOnboardingFoodsCategories,
                            selectedProfessionConsultantData: categoryItem,
                          ));
                        },
                      ),*/
                    ),
                  );
                },
              ),
            ),
          )
/*
          MasonryGridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            padding: EdgeInsets.zero,
            primary: false,
            shrinkWrap: true,
            itemCount: businessOnboardingFoodsCategories.take(6).length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var categoryItem = businessOnboardingFoodsCategories[index];
              return CommonServiceCard(
                service: categoryItem,
                getName: (item) => item.name,
                getIcon: (item) => item.icon ?? '',
                iconHeight: SizeConfig.size80,
                onTap: (item) {
                  Get.to(AllFoodServiceScreen(
                    professionalConsultantCategories:
                    businessOnboardingFoodsCategories,
                    selectedProfessionConsultantData: categoryItem,
                  ));
                },
              );
            },
          )
*/
        ],
      ),
    );
  }
}
