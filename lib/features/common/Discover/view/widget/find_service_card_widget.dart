import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/services_near_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/common/store/view/new_store/products_store_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';

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
              // ViewAllButton(
              //   onTap: () {
              //     Get.to(() => ServicesNearMeScreen(
              //       businessServicesCategories:
              //       businessOnboardingServicesCategories,
              //     ));
              //   },
              // ),

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
                children: businessOnboardingServicesCategories.take(9).map((categoryItem) {
                  return SizedBox(
                    width: itemWidth,
                    child: CommonServiceCard(
                      service: categoryItem,
                      getName: (item) => item.name,
                      getIcon: (item) => item.icon ?? '',
                      iconHeight: SizeConfig.size80,
                      onTap: (item) {
                        Get.to(() => ProductsStoreScreen(
                          // typeOfBusiness: AppConstants.service,
                          productCategory: item.slugId,
                          productCategoryName: item.name,
                        ));
                        // Get.to(() => ServicesNearMeScreen(
                        //   businessServicesCategories:
                        //       businessOnboardingServicesCategories,
                        // ));
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
