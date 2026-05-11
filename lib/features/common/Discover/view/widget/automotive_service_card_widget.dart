import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/all_vehicle_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AutomotiveServiceCardWidget extends StatelessWidget {
  const AutomotiveServiceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget(AppStrings.automotiveShowroom),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(
                builder: (context, constraints) {
              const double spacing = 8;
              const int columns = 3;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: automotiveServiceItemsCategories.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    child: CommonServiceCard(
                      service: item,
                      getName: (i) => i.name,
                      getIcon: (i) => i.icon ?? "",
                      // Hand off to the AllVehicleServiceScreen so the
                      // listing matches the Education/Stay/etc. visual
                      // language (banner + sticky chips). The slug→
                      // backend-CATEGORY mapping now lives inside that
                      // screen alongside its category chips.
                      onTap: (i) => Get.to(() => AllVehicleServiceScreen(
                            automotiveCategories:
                                automotiveServiceItemsCategories,
                            selectedAutomotiveData: i,
                          )),
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
