import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/view/product/product_preview_screen.dart';
import 'package:BlueEra/features/me/product/widget/attribute_two_rows.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class OwnProductCard extends StatelessWidget {
  final GetProductData product;
  final VoidCallback deleteProductApi;
  final double? width;
  final bool isGridShow;

  const OwnProductCard({
    super.key,
    required this.product,
    required this.deleteProductApi,
    this.width,
    this.isGridShow = false,
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
        if (firstTwoKeys.length == 1) break;
      }
      if (firstTwoKeys.length == 1) break;
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
      child: (isGridShow) ? Container(
        width: width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SizedBox(
              height: SizeConfig.size150-10,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: SizeConfig.size150,
                      imagePaths: details?.media ?? [],
                      borderRadius: BorderRadius.zero,
                      onPhotoIndex: (index) {
                      },
                    ),
                  ),
                  // Positioned(
                  //   top: 8,
                  //   right: 8,
                  //   child: _buildIconBox(
                  //     onTap: deleteProductApi,
                  //     Icon(Icons.more_vert, color: Colors.white, size: 16),
                  //   ),
                  // ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size10,
                  horizontal: SizeConfig.size8
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  CustomText(
                    details?.name,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: SizeConfig.size5),

                  // Price Row
                  if (variants.isNotEmpty)
                    Row(
                      children: [
                        CustomText(
                          '₹${variants[0].sellingPrice}',
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.medium,
                          color: AppColors.primaryColor,
                          fontFamily: AppConstants.OpenSans,
                        ),
                         SizedBox(width: SizeConfig.size6),
                        CustomText(
                          ' ₹${variants[0].mrp}',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                          fontFamily: AppConstants.OpenSans,
                        ),
                        if (discountProduct > 0)
                          Padding(
                            padding: EdgeInsets.only(left: SizeConfig.size6),
                            child: CustomText(
                              "${discountProduct}% ${AppStrings.off.tr}",
                              fontSize: SizeConfig.small,
                              color: AppColors.greenShade,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppConstants.OpenSans,
                            ),
                          ),
                      ],
                    ),

                  // // Category and Variants count
                  // Row(
                  //   children: [
                  //     Flexible(
                  //       child: CustomText(
                  //         details?.category.name,
                  //         fontWeight: FontWeight.w600,
                  //         fontSize: SizeConfig.small11,
                  //         color: AppColors.primaryColor,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 6),
                  //     FittedBox(
                  //       fit: BoxFit.scaleDown,
                  //       child: CustomText(
                  //         "(+${variants.length})",
                  //         fontWeight: FontWeight.w600,
                  //         fontSize: SizeConfig.small11,
                  //         color: AppColors.primaryColor,
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  // Attributes (only single)

                  AttributeRows(attributeMap: uniqueAttributes),

                  // const SizedBox(height: 6),
                  //
                  // // Share Product
                  // InkWell(
                  //   onTap: () {
                  //     VisitingCardHelper.buildAndShareProductCard(
                  //       context,
                  //       product,
                  //       index: productPhotoIndex,
                  //     );
                  //   },
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.share,
                  //           color: AppColors.primaryColor, size: 16),
                  //       const SizedBox(width: 4),
                  //       CustomText(
                  //         AppStrings.shareProduct,
                  //         color: AppColors.primaryColor,
                  //         fontWeight: FontWeight.w700,
                  //         fontSize: SizeConfig.small,
                  //       ),
                  //     ],
                  //   ),
                  // ),
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
              width: SizeConfig.size150,
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
                              AppStrings.pricePrefix,
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
                          CustomText(
                              ' ₹${variants[0].mrp}',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                              decoration: TextDecoration.lineThrough
                          ),
                          if (discountProduct > 0)
                            Padding(
                              padding: EdgeInsets.only(left: SizeConfig.size6),
                              child: CustomText(
                                  "${discountProduct}% ${AppStrings.off.tr}",
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.green.shade600
                              ),
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
