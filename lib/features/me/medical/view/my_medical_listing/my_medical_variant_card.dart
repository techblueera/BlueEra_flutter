import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/my_medical_products_response.dart';

class MyMedicalVariantCard extends StatelessWidget {
  final MedicalProductVariants variantItem;
  final bool isShowInGrid;
  final String? categoryId;

  const MyMedicalVariantCard({
    Key? key,
    required this.variantItem,
    required this.isShowInGrid,
    this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => MedicalController());

    final price = controller.getPriceDetails(variantItem.pricing);
    print("Selling Range: ${price.sellingRange}");
    print("MRP Range: ${price.mrpRange}");
    print("Discount Range: ${price.discountRange}");

    return InkWell(
      onTap: () {
        // Get.to(()=> FoodDetailsViewScreen(
        //   productPriceFormat:(foodDetailsData?.priceType == "single")?"${foodDetailsData?.singlePrice ?? "0"}": "$priceText",
        //   data: foodDetailsData ?? GetFoodDetailsModel(),
        // ));
      },
      child: (isShowInGrid)
          ? Container(
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
                      child: (variantItem.images != null &&
                              variantItem.images!.isNotEmpty)
                          ? CustomImageSlideshow(
                              isLoading: false,
                              width: double.infinity,
                              height: SizeConfig.size150,
                              imagePaths: variantItem.images!
                                  .map((i) => i.url ?? '')
                                  .toList(),
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

                  // Info section - flexible
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size10, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            (variantItem.variantName != null && variantItem.variantName!.isNotEmpty)
                                ? variantItem.variantName!
                                : AppStrings.medicalVariantNameNotAvailable.tr,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          if (variantItem.weight != null || variantItem.unit != null)
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.green00, width: 1),
                                      borderRadius: BorderRadius.circular(2)),
                                  padding: EdgeInsets.all(3),
                                  child: Container(
                                    height: 6,
                                    width: 6,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: AppColors.green00),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Flexible(
                                  child: CustomText(
                                    '${variantItem.weight ?? '-'} ${variantItem.unit ?? ''}',
                                    fontSize: 10,
                                    color: Colors.grey,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          Spacer(),
                          Row(
                            children: [
                              CustomText(
                                price.sellingRange.isNotEmpty
                                    ? '₹${price.sellingRange}'
                                    : AppStrings.medicalPriceNotSet.tr,
                                fontSize: 11,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              if (price.mrpRange.isNotEmpty) ...[
                                SizedBox(width: 6),
                                Flexible(
                                  child: CustomText('${AppStrings.medicalMrpRangePrefix.tr} ₹${price.mrpRange}',
                                      fontSize: 9,
                                      color: AppColors.grayText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Edit button - always pinned at bottom
                  Padding(
                    padding: EdgeInsets.only(left: 6, right: 6, bottom: 6),
                    child: InkWell(
                      onTap: () {
                        controller.openEditInventoryBottomSheet(
                          context: context,
                          title: variantItem.variantName ?? AppStrings.medicalEditInventory.tr,
                          variant: variantItem,
                          categoryId: categoryId,
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 13, color: AppColors.primaryColor),
                            SizedBox(width: 4),
                            CustomText(
                              AppStrings.medicalEditInventory,
                              fontSize: 11,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ))
          : Container(
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
                  (variantItem.images != null && variantItem.images!.isNotEmpty)
                      ? CustomImageSlideshow(
                          isLoading: false,
                          width: double.infinity,
                          height: SizeConfig.size150,
                          imagePaths: variantItem.images!
                              .map((i) => i.url ?? '')
                              .toList(),
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
                                  (variantItem.variantName != null && variantItem.variantName!.isNotEmpty)
                                      ? variantItem.variantName!
                                      : AppStrings.medicalVariantNameNotAvailable.tr,
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w600,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  color: AppColors.mainTextColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size10),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.green00, width: 1),
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
                              if (variantItem.weight != null || variantItem.unit != null)
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          width: 0.5, color: AppColors.greyE5)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 0.5),
                                  child: CustomText(
                                    '${variantItem.weight ?? '-'} ${variantItem.unit ?? ''}',
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
                                      price.sellingRange.isNotEmpty
                                          ? price.sellingRange
                                          : AppStrings.medicalNotSet.tr,
                                      fontSize: 10,
                                      color: price.sellingRange.isNotEmpty
                                          ? AppColors.primaryColor
                                          : AppColors.secondaryTextColor,
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
                                      price.mrpRange.isNotEmpty
                                          ? price.mrpRange
                                          : AppStrings.medicalNotSet.tr,
                                      fontSize: 10,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                ],
                              ),
                              if (price.discountRange.isNotEmpty) ...[
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
                                        price.discountRange,
                                        fontSize: 10,
                                        color: AppColors.green00,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),

                          SizedBox(height: SizeConfig.size8),

                          // Edit Inventory Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () {
                                controller.openEditInventoryBottomSheet(
                                  context: context,
                                  title: variantItem.variantName ??
                                      AppStrings.medicalEditInventory.tr,
                                  variant: variantItem,
                                  categoryId: categoryId,
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined,
                                        size: 13,
                                        color: AppColors.primaryColor),
                                    SizedBox(width: 4),
                                    CustomText(
                                      AppStrings.medicalEditInventory,
                                      fontSize: 11,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ),
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
