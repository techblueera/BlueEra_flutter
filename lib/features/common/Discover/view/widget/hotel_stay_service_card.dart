import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class HotelStayServiceCard extends StatelessWidget {
  const HotelStayServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.whiteFC,
      padding: EdgeInsets.all(SizeConfig.size10),
      borderRadius: BorderRadius.circular(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget(AppStrings.bookYourStay),
              SizedBox(
                width: SizeConfig.size8,
              ),
              // _viewAll(),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          SizedBox(
            height: SizeConfig.size180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
              itemCount: stayItemsCategories.length,
              itemBuilder: (context, index) {
                final item = stayItemsCategories[index];
                return InkWell(
                  onTap: () {
                    Get.to(() => AllStayServiceScreen(
                        stayCategories: stayItemsCategories,
                        selectedStayCategory: item));
                  },
                  child: Container(
                    width: SizeConfig.size150,
                    margin: EdgeInsets.only(right: SizeConfig.size12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffDDE2EE), width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              width: double.infinity,
                              color: item.colorCode,
                              child: LocalAssets(imagePath: item.icon ?? ""),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomText(
                                  item.name,
                                  textAlign: TextAlign.center,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w500,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  CustomText(
                                    item.subtitle ?? "N/A",
                                    fontSize: SizeConfig.small,
                                    color: AppColors.secondaryTextColor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
