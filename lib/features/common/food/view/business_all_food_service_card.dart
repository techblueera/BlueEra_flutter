import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/common/visiting_card/helper/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessAllFoodServiceCard extends StatefulWidget {
  final List<GetFoodDetailsModel> allFoodServices;

  const BusinessAllFoodServiceCard({super.key, required this.allFoodServices});

  @override
  State<BusinessAllFoodServiceCard> createState() => _BusinessAllFoodServiceCardState();
}

class _BusinessAllFoodServiceCardState extends State<BusinessAllFoodServiceCard> {
  final controller = getOrPut(() => FoodUploadController());
  late final List<GlobalKey> _cardKey;
  late final List<GetFoodDetailsModel> _allFoodServices;

  @override
  void initState() {
    super.initState();
    _allFoodServices = widget.allFoodServices;
    _cardKey = List.generate(widget.allFoodServices.length, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final crossAxisCount = 2;
        final crossSpacing = 10.0;
        final mainSpacing = 10.0;

        final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
        final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

        final approximateItemHeight = SizeConfig.size310;

        final childAspectRatio = itemWidth / approximateItemHeight;
        return GridView.builder(
          // controller: storesScrollController,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size15
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
            childAspectRatio: childAspectRatio,
          ),
        itemCount: _allFoodServices.length,
        itemBuilder: (context, index) {
          final foodDetailsData = widget.allFoodServices[index];

          final priceOptions = foodDetailsData.priceOptions;

          String priceText = AppStrings.na;
          if (priceOptions != null && priceOptions.isNotEmpty) {
            if (priceOptions.length == 1) {
              priceText = "${priceOptions.first.price ?? ''}";
            } else {
              final prices = priceOptions.map((e) => e.price ?? 0).toList();
              prices.sort();
              priceText = "${prices.first} - ₹${prices.last}";
            }
          }

          return RepaintBoundary(
            key: _cardKey[index],
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blueLightShade,
                boxShadow:  [AppShadows.cardShadow],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.transparent,
                    width: 1.5
                ),
              ),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image slideshow
                      (foodDetailsData.photos?.isNotEmpty??false)
                          ?  CustomImageSlideshow(
                        isLoading: false,
                        width: double.infinity,
                        height: SizeConfig.size150,
                        imagePaths: foodDetailsData.photos ?? [],
                        borderRadius: BorderRadius.circular(10),
                      ) : LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.fill,
                      ),

                      SizedBox(height: SizeConfig.size5),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            CustomText(
                              foodDetailsData.title ?? AppStrings.na,
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
                                  (foodDetailsData.vegType == null)
                                      ? SizedBox()
                                      : Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: controller.getFoodTypeColor(foodDetailsData.vegType),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomText(
                                        "${foodDetailsData.vegType ?? AppStrings.veg}",
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  (foodDetailsData.vegType == null)
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
                                        foodDetailsData.subCategory ?? "",
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
                                    " ${foodDetailsData.nutritionalSummaryPer100g?.caloriesKcal ?? AppStrings.na.tr} ${AppStrings.Cal100gm.tr}",
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
                              child: (foodDetailsData.priceType == "single")
                                  ? CustomText(
                                "₹ ${foodDetailsData.singlePrice ?? "0"}",
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                                  : CustomText(
                                "₹ ${priceText}",
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),

                          ],
                        ),
                      )

                    ],
                  ),

                  Spacer(),
            
                  Column(
                    children: [
                      CommonHorizontalDivider(
                        color: Colors.grey,
                      ),

                      InkWell(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                        onTap: () async {
                          final currentFoodServices = widget.allFoodServices[index];
                          await VisitingCardHelper().shareVisitingCard(
                              _cardKey[index],
                              serviceId: currentFoodServices.id
                          );
                        },
                        child: Container(
                          color: AppColors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size8,
                              vertical: SizeConfig.size8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LocalAssets(
                                    imagePath: AppIconAssets.share_bold,
                                    imgColor: AppColors.primaryColor
                                ),
                                SizedBox(width: SizeConfig.size8),
                                CustomText(
                                    AppStrings.share,
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: SizeConfig.medium,
                                    fontFamily: AppConstants.OpenSans
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // InkWell(
                      //   borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                      //   onTap: () async {
                      //     final currentFoodServices = widget.allFoodServices[index];
                      //     await VisitingCardHelper().shareVisitingCard(
                      //         _cardKey[index],
                      //         serviceId: currentFoodServices.id
                      //     );
                      //   },
                      //   child: Padding(
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: SizeConfig.size8,
                      //       vertical: SizeConfig.size8,
                      //     ),
                      //     child: FittedBox(
                      //       fit: BoxFit.scaleDown,
                      //       child: Row(
                      //         children: [
                      //           CustomText(
                      //               AppStrings.shareCardToSocialMediaGrowBusiness,
                      //               color: AppColors.secondaryTextColor,
                      //               fontWeight: FontWeight.w400,
                      //               fontSize: SizeConfig.small,
                      //               fontFamily: AppConstants.OpenSans),
                      //           SizedBox(width: SizeConfig.size8),
                      //           LocalAssets(
                      //               imagePath: AppIconAssets.share_bold,
                      //               imgColor: AppColors.primaryColor
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  )
            
                ],
              ),
            ),
          );
        },
      );

      },
    );
  }

}
