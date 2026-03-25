import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_customer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';

import 'package:BlueEra/features/me/grocery/model/my_grocery_products_response.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/inner_shadow.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/model/images.dart';

class GroceryProductCard extends StatelessWidget {
  final Products groceryProducts;
  final bool isMyGroceryStore;

  GroceryProductCard({
    Key? key,
    required this.groceryProducts,
    required this.isMyGroceryStore,
  }) : super(key: key);

  final groceryController = Get.find<GroceryController>();


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Images? productImage;
        if (groceryProducts.images != null && groceryProducts.images!.isNotEmpty) {
          productImage = groceryProducts.images![0];
        }

        final variants = groceryProducts.variants ?? [];

        for (final variant in variants) {
          if (productImage != null) {
            if (variant.images == null) {
              variant.images = [productImage];
            } else if (variant.images!.isEmpty) {
              variant.images!.add(productImage);
            }
          }
        }

        // ✅ Bottom sheet instead of navigation
        _showVariantsBottomSheet(Get.context!, variants);
      },
      // onTap: (){
      //
      //     Images? productImage;
      //     if (groceryProducts.images != null && groceryProducts.images!.isNotEmpty) {
      //       productImage = groceryProducts.images![0];
      //     }
      //
      //     final variants = groceryProducts.variants ?? [];
      //
      //     for (final variant in variants) {
      //       if (productImage != null) {
      //         if (variant.images == null) {
      //           variant.images = [productImage]; // Initialize with parent image
      //         } else if (variant.images!.isEmpty) {
      //           variant.images!.add(productImage); // Add parent image to empty list
      //         }
      //       }
      //     }
      //
      //
      //   Get.toNamed(RouteHelper.getMyGroceryVariantScreenRoute(),
      //     arguments: {
      //       ApiKeys.argVariants: variants,
      //       ApiKeys.argIsMyGroceryStore: isMyGroceryStore,
      //       ApiKeys.argIsShowInGrid: true
      //     },
      //   );
      // },
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

  void _showVariantsBottomSheet(
      BuildContext context,
      List<ProductVariants> variants,
      ) {
    final groceryCustomerController = Get.find<GroceryCustomerController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.whiteF1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            bottom: kToolbarHeight,
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTextColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        groceryProducts.name ?? 'All Variants',
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.large,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    CloseButton(),
                  ],
                ),

                const SizedBox(height: 12),

                // Variants List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: variants.length,
                  separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
                  itemBuilder: (_, index) {
                    final variant = variants[index];
                    final productImage = (groceryProducts.images?.isNotEmpty ?? false)
                        ? groceryProducts.images![0].url ?? ''
                        : '';

                    return _variantListItem(
                      context: context,
                      variant: variant,
                      productImage: productImage,
                      controller: groceryCustomerController,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _variantListItem({
    required BuildContext context,
    required ProductVariants variant,
    required String productImage,
    required GroceryCustomerController controller,
  }) {
    final price = groceryController.getPriceDetails(variant.pricing);

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Row(
        children: [
          // Product Image
          (productImage.isNotEmpty)
              ? CustomImageSlideshow(
            isLoading: false,
            width: SizeConfig.size50,
            height: SizeConfig.size50,
            imagePaths: [productImage],
            borderRadius: BorderRadius.circular(6),
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.fill,
              width: SizeConfig.size50,
              height: SizeConfig.size50,
            ),
          ),

          SizedBox(width: SizeConfig.size10),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  variant.variantName ?? '',
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    CustomText(
                      '${variant.quantity}',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 0.5,
                      height: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    PriceRow(
                      sellingPrice: "${price.sellingRange}",
                      mrp: "${price.mrpRange}",
                      discount: "${price.discountRange}",
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: SizeConfig.size10),

          // Dashed Divider
          DashedBorderContainer(
            borderColor: AppColors.greyE5,
            strokeWidth: 1,
            dashLength: 2,
            child: SizedBox(height: SizeConfig.size50, width: 1),
          ),

          SizedBox(width: SizeConfig.size10),

          // Add / Remove Button
          Obx(() {
            final bool isAdded = controller.selectedGroceriesVariants
                .any((v) => v.sId == variant.sId);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: SizeConfig.size70,
              height: SizeConfig.size30,
              decoration: BoxDecoration(
                color: isAdded ? AppColors.red.withValues(alpha: 0.08)
                    : AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isAdded ? AppColors.red : AppColors.primaryColor,
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (isAdded) {
                    controller.removeFromCart(variant);
                  } else {
                    controller.addToCart(
                      variant,
                      productId: variant.sId,
                      inventoryId: groceryProducts.sId,
                      deliveryType: 'RIDER',
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Icon(
                        isAdded ? Icons.remove : Icons.add,
                        key: ValueKey(isAdded),
                        size: 12,
                        color: isAdded ? AppColors.red : AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: CustomText(
                        isAdded ? 'REMOVE' : 'ADD',
                        key: ValueKey(isAdded),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isAdded ? AppColors.red : AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat("d MMMM, yyyy").format(date);
  }

}