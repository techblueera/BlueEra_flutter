import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/attribute_two_rows.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_inventory_bottom_sheet.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_preview_eye_button.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_share_button.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/product_price_edit_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class AdminProductCard extends StatelessWidget {
  final GetProductData product;
  final VoidCallback deleteProductApi;
  final double? width;
  final bool isGridShow;
  final bool showAttributes;

  /// Price-update service for the edit sheet. Defaults to the product-service
  /// inventory endpoint ([InventoryController]); the home-made-product (earn)
  /// screens pass [EarnServiceController.updateProductVariantPrice] instead.
  final PriceUpdateCallback? onUpdatePrice;

  const AdminProductCard({
    super.key,
    required this.product,
    required this.deleteProductApi,
    this.width,
    this.isGridShow = false,
    this.showAttributes = false,
    this.onUpdatePrice,
  });

  // Grid-card name always reserves two lines so cards line up even when a
  // name fits on a single line — the spare line falls to the bottom as blank
  // space. Line-height factor kept explicit so the reserved box and the text
  // agree.
  static const double _gridNameLineHeight = 1.3;
  static double get _gridNameBlockHeight =>
      SizeConfig.medium * _gridNameLineHeight * 2;

  /// Total height of the grid-style card (`isGridShow: true`), derived from
  /// its content so the home strip and the view-all grid can size their cells
  /// identically without hardcoding a magic number.
  static double get gridCardHeight {
    final imageHeight = SizeConfig.size150 - 10;
    const priceRowHeight = 26.0; // FittedBox price row + small buffer
    return imageHeight +
        SizeConfig.size10 * 2 + // vertical padding around details
        _gridNameBlockHeight +
        SizeConfig.size5 + // gap before price
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
    final productId = (details?.id.isNotEmpty ?? false)
        ? details!.id
        : (product.product.sellerClassification?.productId ?? '');

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: (isGridShow) ? Container(
        width: width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          color: AppColors.white,
          border: Border.all(color: AppColors.greyE5)
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
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProductPreviewEyeButton(
                          onTap: () => _openDetails(context),
                        ),
                        const SizedBox(width: 6),
                        ProductShareButton(
                          productId: productId,
                          productName: details?.name,
                        ),
                      ],
                    ),
                  ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name — fixed two-line block so short and long
                  // names occupy the same height (extra space stays at the
                  // bottom of the card).
                  SizedBox(
                    height: _gridNameBlockHeight,
                    width: double.infinity,
                    child: CustomText(
                      details?.name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      height: _gridNameLineHeight,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            Stack(
              children: [
                CustomImageSlideshow(
                  isLoading: false,
                  height: SizeConfig.size200,
                  width: SizeConfig.size150,
                  imagePaths: details?.media ?? [],
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(10.0)),
                  // fit: BoxFit.cover,
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProductPreviewEyeButton(
                        onTap: () => _openDetails(context),
                      ),
                      const SizedBox(width: 6),
                      ProductShareButton(
                        productId: productId,
                        productName: details?.name,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            /// Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 8, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title
                    CustomText(
                        details?.name,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2),
                    SizedBox(height: SizeConfig.size8),

                    /// Price Row
                    PriceRow(
                      sellingPrice: '\u20B9${variants[0].sellingPrice}',
                      mrp: '\u20B9${variants[0].mrp}',
                      discount: "${calculateDiscount('${variants[0].sellingPrice}', '${variants[0].mrp}')}% OFF",
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

  /// Opens the product-details sheet in owner mode. Per-variant edit and
  /// swipe-to-delete live there now — the card no longer carries blunt
  /// edit/delete buttons that could only ever target the first variant.
  void _openDetails(BuildContext context) {
    ProductInventoryBottomSheet.show(
      context,
      product: product,
      isOwner: true,
      onUpdatePrice: onUpdatePrice,
      onChanged: deleteProductApi,
    );
  }
}
