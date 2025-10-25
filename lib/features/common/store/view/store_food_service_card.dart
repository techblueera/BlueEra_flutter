import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/food/view/food_details_view_screen.dart';
import 'package:BlueEra/features/common/store/widget/store_km_away_text_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class StoreFoodServiceCard extends StatelessWidget {
  final GetFoodDetailsModel? foodDetailsData;
  final bool isShowVerticalUi;
  const StoreFoodServiceCard({Key? key,
    this.foodDetailsData, required this.isShowVerticalUi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FoodUploadController controller = Get.put(FoodUploadController());
    final priceOptions = foodDetailsData?.priceOptions;

    String priceText = "N/A";
    if (priceOptions != null && priceOptions.isNotEmpty) {
      if (priceOptions.length == 1) {
        priceText = "${priceOptions.first.price ?? ''}";
      } else {
        final prices = priceOptions.map((e) => e.price ?? 0).toList();
        prices.sort();
        priceText = "${prices.first} - ₹${prices.last}";
      }
    }

    return InkWell(
      onTap: (){
        Get.to(()=> FoodDetailsViewScreen(
          productPriceFormat:(foodDetailsData?.priceType == "single")?"${foodDetailsData?.singlePrice ?? "0"}": "$priceText",
          data: foodDetailsData ?? GetFoodDetailsModel(),
        ));
      },
      child: (isShowVerticalUi)  ? Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image slideshow
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: CustomImageSlideshow(
                isLoading: false,
                width: double.infinity,
                height: SizeConfig.size170,
                imagePaths: foodDetailsData?.photos ?? [],
                borderRadius: BorderRadius.zero,
              ),
            ),

            SizedBox(height: SizeConfig.size6),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  CustomText(
                    foodDetailsData?.title ?? "N/A",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size5),

                  Row(
                    children: [
                      (foodDetailsData?.vegType == null)
                          ? SizedBox()
                          : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: controller.getFoodTypeColor(foodDetailsData?.vegType),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText("${foodDetailsData?.vegType ?? "veg"}",
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      (foodDetailsData?.vegType == null)
                          ? SizedBox()
                          : const SizedBox(
                        width: 6,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.food_bank_outlined,
                            size: 19,
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: CustomText(
                              foodDetailsData?.subCategory ?? "N/A",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w500,
                              color: AppColors.navy,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size5),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Energy : ",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                      ),
                      Expanded(
                        child: CustomText(
                          "${foodDetailsData?.nutritionalSummaryPer100g?.caloriesKcal ?? "N/A"} Cal/100gm",
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size5),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: (foodDetailsData?.priceType == "single")
                        ? CustomText(
                      "Price : ₹ ${foodDetailsData?.singlePrice ?? "0"}",
                      fontSize: SizeConfig.small,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      color: AppColors.primaryColor,
                    )
                        : CustomText(
                      "Price : ₹${priceText}",
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.primaryColor,
                      maxLines: 1,
                    ),
                  ),

                  SizedBox(height: SizeConfig.size6),

                  StoreKmAwayTextWidget(
                    lat: foodDetailsData?.business?.businessLocation?.lat?.toDouble() ?? 0.0,
                    long: foodDetailsData?.business?.businessLocation?.lon?.toDouble() ?? 0.0,
                    isUnderlineShow: false,
                    isPadding: 4.0,
                  ),

                  SizedBox(height: SizeConfig.size10),

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
              width: 140,
              imagePaths: foodDetailsData?.photos ?? [],
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
                            foodDetailsData?.title ?? "N/A",
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

                    Row(
                      children: [
                        (foodDetailsData?.vegType == null)
                            ? SizedBox()
                            : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (foodDetailsData?.vegType == "veg")
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CustomText("${foodDetailsData?.vegType ?? "veg"}",
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        (foodDetailsData?.vegType == null)
                            ? SizedBox()
                            : const SizedBox(
                          width: 6,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.food_bank_outlined,
                              size: 19,
                            ),
                            CustomText(
                              foodDetailsData?.subCategory ?? "N/A",
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
                    SizedBox(height: SizeConfig.size10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "Energy : ",
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                        ),
                        Expanded(
                          child: CustomText(
                            "${foodDetailsData?.nutritionalSummaryPer100g?.caloriesKcal ?? "N/A"} Cal/100gm",
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
                      child: (foodDetailsData?.priceType == "single")
                          ? CustomText(
                        "Price : ₹ ${foodDetailsData?.singlePrice ?? "0"}",
                        fontSize: SizeConfig.small,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        color: AppColors.primaryColor,
                      )
                          : CustomText(
                        "Price : ₹${priceText}",
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.primaryColor,
                        maxLines: 1,
                      ),
                    ),

                    SizedBox(height: SizeConfig.size10),

                    StoreKmAwayTextWidget(
                      lat: foodDetailsData?.business?.businessLocation?.lat?.toDouble() ?? 0.0,
                      long: foodDetailsData?.business?.businessLocation?.lon?.toDouble() ?? 0.0,
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
