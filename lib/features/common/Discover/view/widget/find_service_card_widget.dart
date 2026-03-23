import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/services_near_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class FindServiceCardWidget extends StatelessWidget {
  const FindServiceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.whiteFC,
      padding: EdgeInsets.all(SizeConfig.size10),
      borderRadius: BorderRadius.circular(0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget(AppStrings.findServices),
              SizedBox(
                width: SizeConfig.size8,
              ),
              ViewAllButton(
                onTap: () {
                  Get.to(() => ServicesNearMeScreen(
                    businessServicesCategories:
                    businessOnboardingServicesCategories,
                  ));
                },
              ),

            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:18.0),
            child: MasonryGridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              padding: EdgeInsets.zero,
              primary: false,
              shrinkWrap: true,
              itemCount: businessOnboardingServicesCategories.take(6).length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var categoryItem = businessOnboardingServicesCategories[index];
                return CommonServiceCard(
                  service: categoryItem,
                  getName: (item) => item.name,
                  getIcon: (item) => item.icon ?? '',
                  iconHeight: SizeConfig.size80,
                  onTap: (item) {
                    Get.to(() => ServicesNearMeScreen(
                      businessServicesCategories:
                      businessOnboardingServicesCategories,
                    ));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
