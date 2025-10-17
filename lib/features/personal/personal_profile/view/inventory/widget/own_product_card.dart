import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product_preview_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/attribute_two_rows.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class OwnProductCard extends StatelessWidget {
  final GetProductData product;
  final InventoryController controller;
  final double? width;
  final bool isGridShow;

  const OwnProductCard({
    super.key,
    required this.product,
    required this.controller,
    this.width,
    this.isGridShow = true,
  });

  @override
  Widget build(BuildContext context) {
    final variants = product.product.sellerClassification?.variants ?? [];
    final Map<String, List<dynamic>> uniqueAttributes = {};
    final firstTwoKeys = <String>[];

    // Extract first two attribute keys
    for (var v in variants) {
      for (var key in v.attributes.keys) {
        if (!firstTwoKeys.contains(key)) {
          firstTwoKeys.add(key);
        }
        if (firstTwoKeys.length == 2) break;
      }
      if (firstTwoKeys.length == 2) break;
    }

    // Build unique attributes map
    for (var key in firstTwoKeys) {
      uniqueAttributes[key] = [];
      for (var v in variants) {
        final value = v.attributes[key];
        if (value != null) {
          if (key == 'color' && value is Map<String, dynamic>) {
            final colorMap = {
              "color_name": value["color_name"] ?? "",
              "color_code": value["color_code"] ?? ""
            };
            if (!uniqueAttributes[key]!.any((e) =>
            e is Map &&
                e["color_name"] == colorMap["color_name"] &&
                e["color_code"] == colorMap["color_code"])) {
              uniqueAttributes[key]!.add(colorMap);
            }
          } else {
            if (!uniqueAttributes[key]!.contains(value)) {
              uniqueAttributes[key]!.add(value);
            }
          }
        }
      }
    }

    int discountProduct = calculateDiscount(
      variants[0].sellingPrice.toString(),
      variants[0].mrp.toString(),
    ).toInt();

    int productPhotoIndex = 0;

    ProductDetails? details = product.product.details;

    return GestureDetector(
      onTap: () {
        final productPreviewArgs = mapProductDataToPreviewArgs(product);
        Get.toNamed(
          RouteHelper.getProductPreviewScreenRoute(),
          arguments: {
            ApiKeys.isUserCanCreateVariants: false,
            ApiKeys.argProductData: productPreviewArgs,
          },
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: (isGridShow) ? Container(
          width: width,
          color: AppColors.whiteFE,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 1.1,
                child: Stack(
                  children: [
                    CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: double.infinity,
                      imagePaths: details?.media ?? [],
                      borderRadius: BorderRadius.zero,
                      onPhotoIndex: (index) {
                        productPhotoIndex = index;
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildIconBox(
                        Icon(Icons.more_vert, color: Colors.white, size: 16),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildIconBox(
                        Icon(Icons.share, color: AppColors.white, size: 16),
                        onTap: () {
                          // Handle share icon tap if needed
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Product Details
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    CustomText(
                      details?.name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price Row
                    if (variants.isNotEmpty) ...[
                      Row(
                        children: [
                          CustomText(
                            '₹${variants[0].sellingPrice}',
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.small,
                            color: AppColors.mainTextColor,
                          ),
                          const SizedBox(width: 8),
                          if (discountProduct > 0)
                          CustomText(
                            "${discountProduct}% Off",
                            fontSize: SizeConfig.small11,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w400,
                          ),
                          CustomText(
                            ' ₹${variants[0].mrp}',
                            fontSize: SizeConfig.small11,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Category and Variants count
                    Row(
                      children: [
                        Flexible(
                          child: CustomText(
                            details?.category.name,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.small11,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            "(+${variants.length})",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.small11,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),

                    // Attributes
                    AttributeRows(attributeMap: uniqueAttributes),
                    const SizedBox(height: 6),

                    // Share Product
                    InkWell(
                      onTap: () {
                        VisitingCardHelper.buildAndShareProductCard(
                          context,
                          product,
                          index: productPhotoIndex,
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.share,
                              color: AppColors.primaryColor, size: 16),
                          const SizedBox(width: 4),
                          CustomText(
                            'Share Product',
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.small,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                imagePaths: details?.media ?? [],
                borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
                // fit: BoxFit.cover,
              ),
              const SizedBox(width: 10),

              /// Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 8, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Title + 3-dot menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomText(
                                details?.name,
                                fontSize: SizeConfig.medium,
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
                      SizedBox(height: SizeConfig.size8),

                      /// Price Row
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CustomText(
                                "Price: ",
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor
                            ),

                            CustomText(
                                '₹${variants[0].sellingPrice}',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor
                            ),
                            const SizedBox(width: 6),
                            if (discountProduct > 0) ...[
                              CustomText(
                                  "${discountProduct}% Off",
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.green.shade600
                              ),
                              const SizedBox(width: 6),

                            ],
                            CustomText(
                                ' ₹${variants[0].mrp}',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                                decoration: TextDecoration.lineThrough
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size4),

                      AttributeRows(attributeMap: uniqueAttributes),

                      SizedBox(height: SizeConfig.size8),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(Widget child, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [AppShadows.textFieldShadow],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

ProductPreviewArgs mapProductDataToPreviewArgs(GetProductData productData) {
  final product = productData.product;
  final details = product.details;

  List<ProductListing> listedProducts = [];
  final variants = product.sellerClassification?.variants ?? [];
  if (variants.isNotEmpty) {
    listedProducts = variants.map((variant) {
      final variantName = '${details?.name ?? ''} ' +
          variant.attributes.entries.map((entry) {
            final key = entry.key.toLowerCase();
            final value = entry.value;

            if (key == 'color' && value is Map<String, dynamic>) {
              return value['color_name'] ?? '';
            } else if (value != null) {
              return value.toString();
            } else {
              return '';
            }
          }).where((attr) => attr.isNotEmpty).join(', ');

      return ProductListing(id: variant.id,
        image: variant.mediaRelatedToVariant,
        name: variantName,
        selectedVariants: variant.attributes,
        price: variant.sellingPrice.toString(),
        mrp: variant.mrp.toString(),
        discount: variant.mrp > 0
            ? (((variant.mrp - variant.sellingPrice) / variant.mrp) * 100)
            .toStringAsFixed(2)
            : null,
      );
    }).toList();
  }

  return ProductPreviewArgs(
    productId: details?.id ?? '',
    media: details?.media ?? [],
    name: details?.name ?? '',
    description: details?.description ?? '',
    tags: details?.tags ?? [],
    features: details?.addProductFeatures.map((f) => f.title).toList() ?? [],
    details: details?.addMoreDetails
        .map((d) => DetailPair(d.title, d.details))
        .toList(),
    warranty: details?.productWarranty ?? '',
    // linkOrReferralUrl: details?.linkOrReferralUrl ?? '',
    // expiry: details?.expiry ?? '',
    // userGuide: details?.userGuide ?? [],
    listedProducts: listedProducts,
  );
}
