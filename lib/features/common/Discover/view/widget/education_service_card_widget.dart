import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/all_education_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class EducationServiceCardWidget extends StatelessWidget {
  const EducationServiceCardWidget({super.key});

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
            children: [
              Expanded(
                child: titleWidget("Education Training & Sectors"),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          MasonryGridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            padding: EdgeInsets.zero,
            primary: false,
            shrinkWrap: true,
            itemCount: businessOnboardingEducationTrainingCategories.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var item = businessOnboardingEducationTrainingCategories[index];

              return CommonServiceCard(
                service: item,
                flex: 2,
                getName: (item) => (item.name),
                getIcon: (item) => (item.icon ?? ""),
                iconHeight: SizeConfig.size60,
                onTap: (item) {
                  Get.to(() => AllEducationServiceScreen(
                      professionalConsultantCategories:
                          businessOnboardingEducationTrainingCategories,
                      selectedProfessionConsultantData: item));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
