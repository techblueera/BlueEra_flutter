import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResponsiveRentalCard extends StatelessWidget {
  const ResponsiveRentalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.whiteFC,

      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.paddingXSL),

          titleWidget(AppStrings.rentalServices),
          SizedBox(height: SizeConfig.paddingXSL),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal:18.0),
            child: CommonCardWidget(
              cardMargin: 0,
              padding: 0,borderColorColor: Color(0xffDDE2EE),
              // elevation: 0,
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(24),
              //   side: BorderSide(color: Colors.grey.shade200),
              // ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child:  Row(children: _buildContent(true)),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.paddingXSL),

        ],
      ),
    );
  }

  List<Widget> _buildContent(bool isSmall) {
    return [
      // 1. Icon Image
      Expanded(
        flex: 1,
        child: LocalAssets(
         imagePath: "assets/images/lock_key_icon.png", // Replace with your asset
          // width: 80,
          // height: 80,
          boxFix: BoxFit.contain,
        ),
      ),
      const SizedBox(width:10),

      // 2. Text and Buttons Section
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              'For Rent',
              fontSize: 18, fontWeight: FontWeight.w500),

            const SizedBox(height: 4),
            CustomText(
              'Houses, vehicles & more near you',
            color: AppColors.secondaryTextColor, fontSize: 12),
            const SizedBox(height: 16),

            // 3. Responsive Button Row (Wraps if too many)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InkWell(
                   onTap: (){
                     Get.to(() => AllStayServiceScreen(
                         stayCategories: stayHomeItemsCategories,
                         selectedStayCategory: stayHomeItemsCategories[0]));
                   },
                    child: _buildTag('House Rent')),
                InkWell(onTap: (){
                  commonSnackBar(message: "Coming soon...");
                },child: _buildTag('Vehicle Rent')),
                InkWell(onTap: (){
                  Get.to(() => AllStayServiceScreen(
                      stayCategories: stayHomeItemsCategories,
                      selectedStayCategory: stayHomeItemsCategories[1]));
                },child: _buildTag('Other Rental')),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Match the light blue from image
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomText(
        label,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 10,
      ),
    );
  }
}