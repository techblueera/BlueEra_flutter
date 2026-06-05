import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/services_near_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class FindServiceCardWidget extends StatelessWidget {
  const FindServiceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = Get.find<AuthController>().businessOnboardingServicesCategories;

    return CustomFormCard(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget(AppStrings.findServices),
              SizedBox(
                width: SizeConfig.size8,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(builder: (context, constraints) {
              const double spacing = 8;
              const int columns = 3;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: categories.take(8).map((c) {
                  return SizedBox(
                    width: itemWidth,
                    child: CommonServiceCard(
                      service: c,
                      getName: (item) => item.name ?? '',
                      getIcon: (item) => getServiceCategoryIcon(item.tagId),
                      iconHeight: SizeConfig.size80,
                      onTap: (item) {
                        Get.to(() => ServicesNearMeScreen(
                              serviceCategory: item.tagId,
                              serviceCategoryName: item.name,
                            ));
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
