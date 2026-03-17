import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';

import 'package:BlueEra/features/me/grocery/model/my_grocery_products_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/model/images.dart';

class GroceryProductCard extends StatelessWidget {
  final Products groceryProducts;
  final bool isMyGroceryStore;

  const GroceryProductCard({
    Key? key,
    required this.groceryProducts,
    required this.isMyGroceryStore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){

          Images? productImage;
          if (groceryProducts.images != null && groceryProducts.images!.isNotEmpty) {
            productImage = groceryProducts.images![0];
          }

          final variants = groceryProducts.variants ?? [];

          for (final variant in variants) {
            if (productImage != null) {
              if (variant.images == null) {
                variant.images = [productImage]; // Initialize with parent image
              } else if (variant.images!.isEmpty) {
                variant.images!.add(productImage); // Add parent image to empty list
              }
            }
          }


        Get.toNamed(RouteHelper.getMyGroceryVariantScreenRoute(),
          arguments: {
            ApiKeys.argVariants: variants,
            ApiKeys.argIsMyGroceryStore: isMyGroceryStore,
            ApiKeys.argIsShowInGrid: true
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
                      child: (groceryProducts.images != null &&
                          groceryProducts.images!.isNotEmpty &&
                          groceryProducts.images![0].url != null)
                          ? CustomImageSlideshow(
                        isLoading: false,
                        height: SizeConfig.size130,
                        width: SizeConfig.size140,
                        imagePaths: [groceryProducts.images![0].url!],
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
                              '+${groceryProducts.variants?.length??0} Variants',
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
                              groceryProducts.name ?? '',
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2
                          ),
                        ),
                        if(isMyGroceryStore)
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
                    SizedBox(height: SizeConfig.size4),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CustomText(
                          formatDate(groceryProducts.lastInventoryAddedOrUpdated ?? DateTime.now().toIso8601String()),
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

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat("d MMMM, yyyy").format(date);
  }

}