import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/model/images.dart';
import '../../model/my_medical_products_response.dart';

class MedicalProductCard extends StatelessWidget {
  final Products medicalProducts;
  final String? categoryId;

  const MedicalProductCard({
    Key? key,
    required this.medicalProducts,
    this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){

          Images? productImage;
          if (medicalProducts.images != null && medicalProducts.images!.isNotEmpty) {
            productImage = medicalProducts.images![0];
          }

          final variants = medicalProducts.variants ?? [];

          for (final variant in variants) {
            if (productImage != null) {
              if (variant.images == null) {
                variant.images = [productImage]; // Initialize with parent image
              } else if (variant.images!.isEmpty) {
                variant.images!.add(productImage); // Add parent image to empty list
              }
            }
          }


        Get.toNamed(RouteHelper.getMyMedicalVariantScreenRoute(),
          arguments: {
            ApiKeys.argVariants: variants,
            ApiKeys.argIsShowInGrid: true,
            ApiKeys.argCategoryId: categoryId,
          },
        );
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (medicalProducts.images != null &&
                          medicalProducts.images!.isNotEmpty &&
                          medicalProducts.images![0].url != null)
                          ? CustomImageSlideshow(
                        isLoading: false,
                        height: SizeConfig.size130,
                        width: SizeConfig.size180,
                        imagePaths: [medicalProducts.images![0].url!],
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
                        boxFit: BoxFit.contain,
                      )
                          : LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        height: SizeConfig.size130,
                        width: SizeConfig.size180,
                      ),
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
                              '+${medicalProducts.variants?.length??0} Product',
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
                    bottom: 5,
                    right: 10
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title
                    CustomText(
                        medicalProducts.name ?? '',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2
                    ),
                    SizedBox(height: SizeConfig.size6),

                    /// Last Update
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
                          formatDate(medicalProducts.lastInventoryAddedOrUpdated ?? DateTime.now().toIso8601String()),
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTextColor
                      ),
                    ),

                    Spacer(),

                    /// Edit Inventory Button
                    if (medicalProducts.variants != null &&
                        medicalProducts.variants!.isNotEmpty)
                      Builder(builder: (context) {
                        final controller = getOrPut(() => MedicalController());
                        return InkWell(
                          onTap: () {
                            controller.openEditInventoryBottomSheet(
                              context: context,
                              title: medicalProducts.name ?? 'Edit Inventory',
                              variant: medicalProducts.variants!.first,
                              categoryId: categoryId,
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                                    size: 12,
                                    color: AppColors.primaryColor),
                                SizedBox(width: 4),
                                CustomText(
                                  'Edit',
                                  fontSize: 11,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat("d MMMM, yyyy").format(date);
  }

}