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
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
            children: [
              Expanded(
                child: titleWidget(AppStrings.bookYourStay),
              ),
              SizedBox(
                width: SizeConfig.size8,
              ),
              // _viewAll(),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          MasonryGridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            padding: EdgeInsets.zero,
            primary: false,
            shrinkWrap: true,
            itemCount: stayItemsCategories.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var item = stayItemsCategories[index];
              return InkWell(
                onTap: (){
                  Get.to(() => AllStayServiceScreen(
                      stayCategories: stayItemsCategories,
                      selectedStayCategory: item));
                },
                child: AspectRatio(
                  aspectRatio: 1.0, // Adjusted for a more square look like the design
                  child: Container(
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20), // Increased for smoother look
                      border: Border.all(color: const Color(0xffDDE2EE), width: 1.0),
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
                              color: item.colorCode, // The soft blue tint from your image
                              child: LocalAssets(imagePath: item.icon ?? ""),
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
                                  item.name,
                                  textAlign: TextAlign.center,
                                  color: AppColors.mainTextColor, // White text looks better on Red
                                  fontWeight: FontWeight.w500,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // If you want the "Premium Rooms" subtitle from image 2:
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  CustomText(
                                    item.subtitle??"N/A",
                                    fontSize: SizeConfig.small,
                                    color:AppColors.secondaryTextColor,
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
                ),
              );

            },
          ),
        ],
      ),
    );
  }
}
