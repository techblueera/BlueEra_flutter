import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/all_professional_consultant_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class ProfessionalsCardWidget extends StatelessWidget {
  const ProfessionalsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.whiteFC,
      borderRadius: BorderRadius.circular(0),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget(AppStrings.professionals),
              SizedBox(
                width: SizeConfig.size8,
              ),
              ViewAllButton(
                onTap: () {
                  Get.to(() => AllProfessionConsultantScreen(
                    professionalConsultantCategories:
                    individualOnboardingConsultationList,
                  ));
                },
              ),

            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: LayoutBuilder(builder: (context, constraints) {
              const double spacing = 6;
              const int columns = 3;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: individualOnboardingConsultationList.take(6).map((categoryItem) {
                  return SizedBox(
                    width: itemWidth,
                    child: CommonServiceCard(
                      service: categoryItem,
                      getName: (item) => item.name,
                      getIcon: (item) => item.icon ?? '',
                      iconHeight: SizeConfig.size80,
                      onTap: (item) {
                        Get.to(() => AllProfessionConsultantScreen(
                            professionalConsultantCategories:
                                individualOnboardingConsultationList,
                            selectedProfessionConsultantData: item));
                      },
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }
}
