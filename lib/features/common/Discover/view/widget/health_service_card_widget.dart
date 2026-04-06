import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/health_care_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthServiceCardWidget extends StatelessWidget {
  const HealthServiceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.whiteFC,
      borderRadius: BorderRadius.circular(0),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget(AppStrings.healthcareServices.tr),
              SizedBox(width: SizeConfig.size8),
              ViewAllButton(
                onTap: () {
                  var categoryItem = healthCareList[0];

                  Get.to(HealthCareListingScreen(
                    selectedProfessionConsultantData: categoryItem,
                  ));
                },
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:18.0),
            child: SizedBox(
              height: SizeConfig.size124,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                primary: false,
                itemCount: healthCareList.length,
                scrollDirection: Axis.horizontal,
                physics: AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  var categoryItem = healthCareList[index];
                  return CommonServiceCardHealth(
                    service: categoryItem,
                    getName: (item) => item.name,
                    getIcon: (item) => item.icon ?? '',
                    margin: EdgeInsets.only(right: 6),
                    onTap: (item) {
                      Get.to(HealthCareListingScreen(
                        selectedProfessionConsultantData: categoryItem,
                      ));
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
