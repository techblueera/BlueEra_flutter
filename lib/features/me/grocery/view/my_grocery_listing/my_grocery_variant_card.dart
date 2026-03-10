import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/my_grocery_products_reponse.dart';

class MyGroceryVariantCard extends StatelessWidget {
  final Variants variantItem;
  final bool isShowInGrid;

  const MyGroceryVariantCard({
    Key? key,
    required this.variantItem,
    required this.isShowInGrid
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => GroceryController());

    final price = controller.getPriceDetails(variantItem.pricing);
    print("Selling Range: ${price.sellingRange}");
    print("MRP Range: ${price.mrpRange}");
    print("Discount Range: ${price.discountRange}");

    return InkWell(
      onTap: (){
        // Get.to(()=> FoodDetailsViewScreen(
        //   productPriceFormat:(foodDetailsData?.priceType == "single")?"${foodDetailsData?.singlePrice ?? "0"}": "$priceText",
        //   data: foodDetailsData ?? GetFoodDetailsModel(),
        // ));
      },
      child: (isShowInGrid) ? Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image slideshow
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                  (variantItem.images!=null  &&
                      variantItem.images!.isNotEmpty)
                      ? CustomImageSlideshow(
                    isLoading: false,
                    width: double.infinity,
                    height: SizeConfig.size150,
                    imagePaths: variantItem.images!.map((i)=> i.url??'').toList(),
                    borderRadius: BorderRadius.zero,
                    boxFit: BoxFit.contain,
                  )
                      : LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.fill,
                    height: SizeConfig.size150,
                    width: double.infinity,
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size6,
                    horizontal: SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    SizedBox(
                      // height: SizeConfig.size28,
                      child: CustomText(
                        variantItem.variantName,
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),

                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border:
                              Border.all(color: AppColors.green00, width: 1),
                              borderRadius: BorderRadius.circular(2)),
                          padding: EdgeInsets.all(3.5),
                          child: Container(
                            height: 7,
                            width: 7,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: AppColors.green00),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size6),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border:
                              Border.all(width: 0.5, color: AppColors.greyE5)),
                          padding:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                          child: CustomText(
                            '${variantItem.inventory?.batches?[0].quantity}',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size6),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomText(
                              "${AppStrings.price.tr}: ",
                              fontSize: 10,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(width: SizeConfig.size3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CustomText(
                                "${price.sellingRange}",
                                fontSize: 10,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomText(
                              "${AppStrings.mrp.tr}: ",
                              fontSize: 10,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(width: SizeConfig.size3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CustomText(
                                "${price.mrpRange}",
                                fontSize: 10,
                                color: AppColors.grayText,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomText(
                              "${AppStrings.discount.tr}: ",
                              fontSize: 10,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(width: SizeConfig.size3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CustomText(
                                "${price.discountRange}",
                                fontSize: 10,
                                color: AppColors.green00,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.paddingXSmall),


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
            (variantItem.images!=null  &&
                variantItem.images!.isNotEmpty)
                ? CustomImageSlideshow(
              isLoading: false,
              width: double.infinity,
              height: SizeConfig.size150,
              imagePaths: variantItem.images!.map((i)=> i.url??'').toList(),
              borderRadius: BorderRadius.zero,
            )
                : LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
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
                            variantItem.variantName,
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
                        Container(
                          decoration: BoxDecoration(
                              border:
                              Border.all(color: AppColors.green00, width: 1),
                              borderRadius: BorderRadius.circular(2)),
                          padding: EdgeInsets.all(3.5),
                          child: Container(
                            height: 7,
                            width: 7,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: AppColors.green00),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size6),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border:
                              Border.all(width: 0.5, color: AppColors.greyE5)),
                          padding:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                          child: CustomText(
                            '${variantItem.quantity}',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size6),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomText(
                              "${AppStrings.price.tr}: ",
                              fontSize: 10,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(width: SizeConfig.size3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CustomText(
                                "${price.sellingRange}",
                                fontSize: 10,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomText(
                              "${AppStrings.mrp.tr}: ",
                              fontSize: 10,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(width: SizeConfig.size3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CustomText(
                                "${price.mrpRange}",
                                fontSize: 10,
                                color: AppColors.grayText,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomText(
                              "${AppStrings.discount.tr}: ",
                              fontSize: 10,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(width: SizeConfig.size3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CustomText(
                                "${price.discountRange}",
                                fontSize: 10,
                                color: AppColors.green00,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
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
