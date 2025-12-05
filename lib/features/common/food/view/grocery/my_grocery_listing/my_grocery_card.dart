import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/food/view/food_details_view_screen.dart';
import 'package:BlueEra/features/common/store/widget/store_km_away_text_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyGroceryCard extends StatelessWidget {
  // final GetFoodDetailsModel? foodDetailsData;
  final bool isShowInGrid;

  const MyGroceryCard({
    Key? key,
    // this.foodDetailsData,
    required this.isShowInGrid
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final FoodUploadController controller = getOrPut(() => FoodUploadController());
    //
    // final priceOptions = foodDetailsData?.priceOptions;
    //
    // String priceText = AppStrings.na;
    // if (priceOptions != null && priceOptions.isNotEmpty) {
    //   if (priceOptions.length == 1) {
    //     priceText = "${priceOptions.first.price ?? ''}";
    //   } else {
    //     final prices = priceOptions.map((e) => e.price ?? 0).toList();
    //     prices.sort();
    //     priceText = "${prices.first} - ₹${prices.last}";
    //   }
    // }

    return InkWell(
      onTap: (){
        // Get.to(()=> FoodDetailsViewScreen(
        //   productPriceFormat:(foodDetailsData?.priceType == "single")?"${foodDetailsData?.singlePrice ?? "0"}": "$priceText",
        //   data: foodDetailsData ?? GetFoodDetailsModel(),
        // ));
      },
      child: (isShowInGrid)  ? Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image slideshow
              SizedBox(
                height: SizeConfig.size150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                  // (foodDetailsData?.photos?.isNotEmpty??false)
                  //     ?
                  CustomImageSlideshow(
                    isLoading: false,
                    width: double.infinity,
                    height: SizeConfig.size150,
                    imagePaths: ['assets/category/dal/oilnew.png'],
                    isLocal: true,
                    borderRadius: BorderRadius.zero,
                  )
                  //     : LocalAssets(
                  //   imagePath: AppIconAssets.place_holder_image,
                  //   boxFix: BoxFit.fill,
                  // ),
                ),
              ),

              SizedBox(height: SizeConfig.size5),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    CustomText(
                      "Basmati Rice",
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size5),

                    // Veg label + category
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          // (foodDetailsData?.vegType == null)
                          //     ? SizedBox()
                          //     :
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.green7F,
                              // color: controller.getFoodTypeColor(foodDetailsData?.vegType),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: CustomText(
                                AppStrings.veg,
                                // "${foodDetailsData?.vegType ?? AppStrings.veg}",
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                          // (foodDetailsData?.vegType == null)
                          //     ? SizedBox()
                          //     : const SizedBox(
                          //   width: 6,
                          // ),
                          Row(
                            children: [
                              Icon(
                                Icons.food_bank_outlined,
                                size: 19,
                              ),
                              CustomText(
                                AppStrings.na,
                                // foodDetailsData?.subCategory ?? AppStrings.na,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w500,
                                color: AppColors.navy,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size5),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            AppStrings.energyPrefix,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                          CustomText(
                            "50 ${AppStrings.Cal100gm.tr}",
                            // " ${foodDetailsData?.nutritionalSummaryPer100g?.caloriesKcal ?? AppStrings.na.tr} ${AppStrings.Cal100gm.tr}",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size5),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CustomText(
                        "₹65982",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )
                      // (foodDetailsData?.priceType == "single")
                      //     ? CustomText(
                      //   "₹ ${foodDetailsData?.singlePrice ?? "0"}",
                      //   fontSize: SizeConfig.small,
                      //   fontWeight: FontWeight.w700,
                      //   color: AppColors.primaryColor,
                      //   overflow: TextOverflow.ellipsis,
                      //   maxLines: 1,
                      // )
                      //     : CustomText(
                      //   "₹ ${priceText}",
                      //   fontSize: SizeConfig.small,
                      //   fontWeight: FontWeight.w700,
                      //   color: AppColors.primaryColor,
                      //   overflow: TextOverflow.ellipsis,
                      //   maxLines: 1,
                      // ),
                    ),

                    SizedBox(height: SizeConfig.size8),

                    StoreKmAwayTextWidget(
                      // lat: foodDetailsData?.business?.businessLocation?.lat?.toDouble() ?? 0.0,
                      // long: foodDetailsData?.business?.businessLocation?.lon?.toDouble() ?? 0.0,
                      lat: 52.245,
                      long: 78.256,
                      isUnderlineShow: false,
                      isPadding: 4.0,
                    ),


                  ],
                ),
              )

            ],
          )
      ) : Container(
        height: SizeConfig.size200,
        decoration: BoxDecoration(
          color: AppColors.whiteFE,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 1.4,
              offset: const Offset(0, 0.7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Product Image
            CustomImageSlideshow(
              isLoading: false,
              height: SizeConfig.size200,
              width: SizeConfig.size140,
              imagePaths: ['assets/category/dal/oilnew.png'],
              isLocal: true,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
              // fit: BoxFit.cover,
            ),
            const SizedBox(width: 10),

            /// Product Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomText(
                            "Basmati Rice",
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                        Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size10),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          // (foodDetailsData?.vegType == null)
                          //     ? SizedBox()
                          //     :
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.green7F,
                              // color: controller.getFoodTypeColor(foodDetailsData?.vegType),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: CustomText(
                                AppStrings.veg,
                                // "${foodDetailsData?.vegType ?? AppStrings.veg}",
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                          // (foodDetailsData?.vegType == null)
                          //     ? SizedBox()
                          //     : const SizedBox(
                          //   width: 6,
                          // ),
                          Row(
                            children: [
                              Icon(
                                Icons.food_bank_outlined,
                                size: 19,
                              ),
                              CustomText(
                                AppStrings.na,
                                // foodDetailsData?.subCategory ?? AppStrings.na,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w500,
                                color: AppColors.navy,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          AppStrings.energyPrefix,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                        ),
                        Expanded(
                          child: CustomText(
                            "50 ${AppStrings.Cal100gm.tr}",
                            // "${foodDetailsData?.nutritionalSummaryPer100g?.caloriesKcal ?? "N/A"} Cal/100gm",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.size10),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CustomText(
                        "₹65982",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )


                      // (foodDetailsData?.priceType == "single")
                      //     ? CustomText(
                      //   "Price : ₹ ${foodDetailsData?.singlePrice ?? "0"}",
                      //   fontSize: SizeConfig.small,
                      //   overflow: TextOverflow.ellipsis,
                      //   maxLines: 1,
                      //   color: AppColors.primaryColor,
                      // )
                      //     : CustomText(
                      //   "Price : ₹${priceText}",
                      //   fontWeight: FontWeight.w600,
                      //   overflow: TextOverflow.ellipsis,
                      //   color: AppColors.primaryColor,
                      //   maxLines: 1,
                      // ),
                    ),

                    SizedBox(height: SizeConfig.size10),

                    StoreKmAwayTextWidget(
                      // lat: foodDetailsData?.business?.businessLocation?.lat?.toDouble() ?? 0.0,
                      // long: foodDetailsData?.business?.businessLocation?.lon?.toDouble() ?? 0.0,
                      lat: 52.245,
                      long: 78.256,
                      isUnderlineShow: false,
                      isPadding: 4.0,
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
