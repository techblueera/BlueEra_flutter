import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_rider_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/model/images.dart';

enum GroceryCardFlowType { myStore, selfPickup, rider }

class GroceryProductCard extends StatelessWidget {
  final GroceryProductData groceryProducts;
  final GroceryCardFlowType flowType;
  final String? bId; // only needed for selfPickup flow

  GroceryProductCard({
    Key? key,
    required this.groceryProducts,
    required this.flowType,
    this.bId,
  }) : super(key: key);

  GroceryController get _groceryController => getOrPut(() => GroceryController());
  ViewBusinessDetailsController get _viewBusinessDetailsController =>
      getOrPut(() => ViewBusinessDetailsController());

  List<ProductVariants> get _variants {
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
    return variants;
  }

  @override
  Widget build(BuildContext context) {
    final price = _groceryController.getPriceDetails(
      groceryProducts.variants?.isNotEmpty == true
          ? groceryProducts.variants![0].pricing
          : null,
    );
    final imageUrl = groceryProducts.images?.isNotEmpty == true
        ? groceryProducts.images![0].url ?? ''
        : '';

    return InkWell(
      onTap: () => _showVariantsBottomSheet(Get.context!, _variants),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + badges ────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: SizedBox(
                    height: SizeConfig.size140,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.cover,
                            ),
                          )
                        : LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.cover,
                          ),
                  ),
                ),

                // "+N Variants" badge — bottom-right
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.blackMite,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomText(
                          AppStrings.groceryViewVariantsBadge.trParams({'count': '${groceryProducts.variants?.length ?? 0}'}),
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.whiteFE,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3-dot menu — top-right (myStore only)
                if (flowType == GroceryCardFlowType.myStore)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.blackMite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: AppColors.whiteFE,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Details ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 9.0,
                vertical: SizeConfig.size6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  CustomText(
                    groceryProducts.name ?? '',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size6),

                  // Veg dot + quantity badge
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: const EdgeInsets.all(3.5),
                        child: Container(
                          height: 7,
                          width: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00,
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(width: 0.5, color: AppColors.greyE5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        child: CustomText(
                          '${groceryProducts.variants?[0].quantity ?? ''}',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size6),

                  // Price
                  PriceRow(
                    sellingPrice: '${price.sellingRange}',
                    mrp: '${price.mrpRange}',
                    discount: '${price.discountRange}',
                  ),
                  SizedBox(height: SizeConfig.size8),

                  // Action button
                  if (flowType == GroceryCardFlowType.myStore)
                    // _buildEditButton(onTap: () {})
                    SizedBox()
                  else
                    _buildCardAddButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAddButton() {
    return Obx(() {
      final bool isAdded;
      if (flowType == GroceryCardFlowType.selfPickup) {
        final ctrl = Get.find<GrocerySelfPickupConsumerController>();
        isAdded = groceryProducts.variants?.any(
              (v) => ctrl.selectedGroceriesVariants.any((s) => s.sId == v.sId),
            ) ??
            false;
      } else {
        final ctrl = Get.find<GroceryRiderConsumerController>();
        isAdded = groceryProducts.variants?.any(
              (v) => ctrl.selectedGroceriesVariants.any((s) => s.sId == v.sId),
            ) ??
            false;
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: SizeConfig.size30,
        decoration: BoxDecoration(
          color: isAdded
              ? AppColors.green00.withValues(alpha: 0.08)
              : AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAdded ? AppColors.green00 : AppColors.primaryColor,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showVariantsBottomSheet(Get.context!, _variants),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isAdded ? Icons.check : Icons.add,
                  key: ValueKey(isAdded),
                  size: 12,
                  color: isAdded ? AppColors.green00 : AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: CustomText(
                  isAdded ? AppStrings.groceryViewAddedCaps.tr : AppStrings.groceryViewAddCaps.tr,
                  key: ValueKey(isAdded),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAdded ? AppColors.green00 : AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showVariantsBottomSheet(
      BuildContext context,
      List<ProductVariants> variants,
      ) {

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
                        groceryProducts.name ?? AppStrings.groceryViewAllVariants.tr,
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
  }) {
    final GrocerySelfPickupConsumerController? _selfPickupController =
        flowType == GroceryCardFlowType.selfPickup
            ? Get.find<GrocerySelfPickupConsumerController>()
            : null;

    final GroceryRiderConsumerController? _riderController =
        flowType == GroceryCardFlowType.rider
            ? Get.find<GroceryRiderConsumerController>()
            : null;

    final price = _groceryController.getPriceDetails(variant.pricing);

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


          if(flowType == GroceryCardFlowType.selfPickup || flowType == GroceryCardFlowType.rider)...[
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
              final bDetails = _viewBusinessDetailsController.visitedBusinessProfileDetails?.data;

              final bool isAdded = flowType == GroceryCardFlowType.selfPickup
                  ? (_selfPickupController?.selectedGroceriesVariants
                          .any((v) => v.sId == variant.sId) ??
                      false)
                  : (_riderController?.selectedGroceriesVariants
                          .any((v) => v.sId == variant.sId) ??
                      false);

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
                    if (flowType == GroceryCardFlowType.selfPickup) {
                      if (isAdded) {
                        _selfPickupController?.removeFromCart(variant);
                      } else {
                        _selfPickupController?.addToCart(
                          variant,
                          productId: variant.sId,
                          inventoryId: groceryProducts.sId,
                          businessId: bId,
                          businessName: bDetails?.businessName,
                          businessLogo: bDetails?.logo,
                          businessAddress: bDetails?.address,
                        );
                      }
                    } else {
                      if (isAdded) {
                        _riderController?.removeFromCart(variant);
                      } else {
                        _riderController?.addToCart(
                          variant,
                          productId: variant.sId,
                          inventoryId: groceryProducts.sId,
                        );
                      }
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
                          isAdded ? AppStrings.groceryViewRemoveCaps.tr : AppStrings.groceryViewAddCaps.tr,
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
          ]
          else ...[
            SizedBox(width: SizeConfig.size10),
            // OWNER VIEW: Edit Inventory / Manage
            _buildEditButton(
                onTap: () {  }
            )
          ],

        ],
      ),
    );
  }

  Widget _buildEditButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: SizeConfig.size30,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.pen_line,
              height: 14,
              width: 14,
              imgColor: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.groceryViewEditCaps.tr,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

}