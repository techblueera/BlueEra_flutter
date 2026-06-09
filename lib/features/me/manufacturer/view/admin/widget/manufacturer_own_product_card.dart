import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_product_preview_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_attribute_two_rows.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/product_price_edit_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class ManufacturerOwnProductCard extends StatelessWidget {
  final GetProductData product;
  final VoidCallback deleteProductApi;
  final double? width;
  final bool isGridShow;
  final bool showAttributes;

  const ManufacturerOwnProductCard({
    super.key,
    required this.product,
    required this.deleteProductApi,
    this.width,
    this.isGridShow = false,
    this.showAttributes = true,
  });

  static const double _gridNameLineHeight = 1.3;
  static double get _gridNameBlockHeight =>
      SizeConfig.medium * _gridNameLineHeight * 2;

  /// Total height of the grid-style card (`isGridShow: true`), derived from its
  /// content so a horizontal strip and a view-all grid can size cells the same.
  static double get gridCardHeight {
    final imageHeight = SizeConfig.size150 - 10;
    const priceRowHeight = 26.0;
    return imageHeight +
        SizeConfig.size10 * 2 +
        _gridNameBlockHeight +
        SizeConfig.size5 +
        priceRowHeight;
  }

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

    ProductDetails? details = product.product.details;

    return GestureDetector(
      onTap: () {
        final productPreviewArgs = mapProductDataToPreviewArgs(product);
        Get.toNamed(
          RouteHelper.getManufacturerProductPreviewScreenRoute(),
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
            // ManufacturerProduct Image
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
                  // Owner card — price-edit shortcut.
                  Positioned(
                    right: 6,
                    top: 6,
                    child: _editButton(context),
                  ),
                ],
              ),
            ),

            // ManufacturerProduct Details
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size10,
                  horizontal: SizeConfig.size8
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ManufacturerProduct Name
                  CustomText(
                    details?.name,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: SizeConfig.size5),

                  // Price Row
                  if (variants.isNotEmpty)
                    PriceRow(
                      sellingPrice: '\u20B9${variants[0].sellingPrice}',
                      mrp: '\u20B9${variants[0].mrp}',
                      discount: "${calculateDiscount('${variants[0].sellingPrice}', '${variants[0].mrp}')}% OFF",
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
                  if (showAttributes)
                    ManufacturerAttributeRows(attributeMap: uniqueAttributes),

                  // const SizedBox(height: 6),
                  //
                  // // Share ManufacturerProduct
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
            /// ManufacturerProduct Image
            CustomImageSlideshow(
              isLoading: false,
              height: SizeConfig.size200,
              width: SizeConfig.size150,
              imagePaths: details?.media ?? [],
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
              // fit: BoxFit.cover,
            ),
            const SizedBox(width: 10),

            /// ManufacturerProduct Details
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
                    PriceRow(
                      sellingPrice: '\u20B9${variants[0].sellingPrice}',
                      mrp: '\u20B9${variants[0].mrp}',
                      discount: "${calculateDiscount('${variants[0].sellingPrice}', '${variants[0].mrp}')}% OFF",
                    ),
                    SizedBox(height: SizeConfig.size4),

                    ManufacturerAttributeRows(attributeMap: uniqueAttributes),

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

  // Opens the price-edit sheet for this product. Updates go through the
  // product-service inventory endpoint via ManufacturerInventoryController.
  void _onEditTap(BuildContext context) {
    ProductPriceEditSheet.show(
      context: context,
      product: product,
      onUpdate: getOrPut(() => ManufacturerInventoryController())
          .updateProductVariantPrice,
    );
  }

  Widget _editButton(BuildContext context) {
    return InkWell(
      onTap: () => _onEditTap(context),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.primaryColor, width: 1.0),
        ),
        child: LocalAssets(
          imagePath: AppIconAssets.pen_line,
          imgColor: AppColors.primaryColor,
          height: 14,
          width: 14,
          boxFix: BoxFit.cover,
        ),
      ),
    );
  }

}

ManufacturerProductPreviewArgs mapProductDataToPreviewArgs(GetProductData productData) {
  final product = productData.product;
  final details = product.details;

  List<ManufacturerProductListing> listedProducts = [];
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

      return ManufacturerProductListing(id: variant.id,
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

  return ManufacturerProductPreviewArgs(
    productId: details?.id ?? '',
    media: details?.media ?? [],
    name: details?.name ?? '',
    description: details?.description ?? '',
    tags: details?.tags ?? [],
    features: details?.addProductFeatures.map((f) => f.title).toList() ?? [],
    details: details?.addMoreDetails
        .map((d) => ManufacturerDetailPair(d.title, d.details))
        .toList(),
    warranty: details?.productWarranty ?? '',
    // linkOrReferralUrl: details?.linkOrReferralUrl ?? '',
    // expiry: details?.expiry ?? '',
    // userGuide: details?.userGuide ?? [],
    listedProducts: listedProducts,
  );
}
