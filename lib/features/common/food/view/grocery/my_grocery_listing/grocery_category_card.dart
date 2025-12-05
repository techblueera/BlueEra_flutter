import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/my_grocery_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryCategoryCard extends StatelessWidget {
  // final ProductStore? productStore;
  // final bool isShowInGrid;
  const GroceryCategoryCard({
    Key? key,
    // this.productStore,
    // required this.isShowInGrid
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        Get.to(()=> MyGroceryScreen(isShowInGrid: true));
      },
      child: Container(
        height: SizeConfig.size130,
        padding: EdgeInsets.only(bottom: 5.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          // boxShadow: [
          //   BoxShadow(
          //     color: AppColors.shadowColor,
          //     blurRadius: 1.4,
          //     offset: const Offset(0, 0.7),
          //   ),
          // ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Grocery Category Image
            Stack(
              children: [
                Card(
                  color: AppColors.whiteFE,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CustomImageSlideshow(
                      isLoading: false,
                      height: SizeConfig.size130,
                      width: SizeConfig.size180,
                      isLocal: true,
                      imagePaths: ['assets/category/dal/oilnew.png'],
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
                      // fit: BoxFit.cover,
                    ),
                  ),
                ),

                Positioned(
                    bottom: 10.0,
                    right: 10.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                              color: AppColors.blackMite,
                              borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: CustomText(
                              '+10 Product',
                              fontSize: SizeConfig.extraSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.whiteFE
                          ),
                        ),
                      ),
                    )
                )
              ],
            ),
            SizedBox(width: SizeConfig.size6),

            /// Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 8,
                    right: 10
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title + 3-dot menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomText(
                              'Staples & Grains',
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2
                          ),
                        ),
                        Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size6),

                    /// Price Row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CustomText(
                          'Last Update: ',
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor
                      ),
                    ),
                    SizedBox(height: SizeConfig.size2),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CustomText(
                          '20 April,2025',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTextColor
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}