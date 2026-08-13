import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_attribute_two_rows.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_inventory_bottom_sheet.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_preview_eye_button.dart';
import 'package:BlueEra/widgets/card_name_slack.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class ManufacturerAdminProductCard extends StatelessWidget {
  final GetProductData product;
  final VoidCallback deleteProductApi;
  final double? width;
  final bool isGridShow;
  final bool showAttributes;

  const ManufacturerAdminProductCard({
    super.key,
    required this.product,
    required this.deleteProductApi,
    this.width,
    this.isGridShow = false,
    this.showAttributes = true,
  });

  static const double _gridNameLineHeight = 1.3;

  /// Unscaled two-line height — the baseline [gridCardHeight] is built from.
  static double get _gridNameBlockHeight =>
      SizeConfig.medium * _gridNameLineHeight * 2;

  /// Two-line height at the device's CURRENT text scale. `fontSize * factor *
  /// 2` is only two lines when the text renders at `fontSize`, and nothing in
  /// this app clamps the system font setting. Mirrors [AdminProductCard].
  static double _gridNameBlockHeightOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(SizeConfig.medium) *
      _gridNameLineHeight *
      2;

  /// Total height of the grid-style card (`isGridShow: true`), derived from its
  /// content so a horizontal strip and a view-all grid can size cells the same.
  ///
  /// Text-scaled: the rail gives the card a TIGHT height, so if the name grows
  /// with the user's font size and this doesn't, the card overflows its rail.
  static double get gridCardHeight {
    final imageHeight = SizeConfig.size150 - 10;
    const priceRowHeight = 26.0;
    final textScale =
        WidgetsBinding.instance.platformDispatcher.textScaleFactor;
    return imageHeight +
        SizeConfig.size10 * 2 +
        _gridNameBlockHeight * textScale +
        SizeConfig.size5 +
        priceRowHeight;
  }

  /// Whether the product reads as in stock — true when ANY variant is
  /// sellable. One available variant still means a customer can buy it, so
  /// only a wholly-flagged product reads as out.
  static bool _inStock(List<Variant> variants) =>
      variants.isEmpty || variants.any((v) => v.stock);

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
      onTap: () => _openDetails(context),
      child: (isGridShow) ? CardNameSlack(
        // Measures the name against this card's own width so the line it
        // doesn't use is spent at the BOTTOM of the card instead of as a gap
        // under the title. `SizeConfig.size8 * 2` is the details padding.
        text: details?.name ?? '',
        fontSize: SizeConfig.medium,
        lineHeight: _gridNameLineHeight,
        horizontalPadding: SizeConfig.size8 * 2,
        builder: (context, nameSlack) => Container(
        width: width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          color: AppColors.white,
          border: Border.all(color: AppColors.greyE5),
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
                  Positioned(
                    top: 6,
                    left: 6,
                    child: ProductPreviewEyeButton(
                      onTap: () => _openDetails(context),
                    ),
                  ),
                  // Stock state on the photo, where the eye lands first when
                  // scanning a rail.
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: StockStatusPill(
                        inStock: _inStock(variants), onImage: true),
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
                  // ManufacturerProduct Name — natural height, one line or two.
                  // The card still occupies the same total height as its
                  // neighbours because the line a short name didn't use is
                  // added at the END of the card (see the SizedBox after the
                  // attributes), instead of sitting as a hole under the title.
                  CustomText(
                    details?.name,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    height: _gridNameLineHeight,
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

                  // The name line this card didn't need, spent here so the
                  // cards stay the same height with the blank at the bottom.
                  if (nameSlack > 0) SizedBox(height: nameSlack),

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
                  child: ProductPreviewEyeButton(
                    onTap: () => _openDetails(context),
                  ),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: StockStatusPill(
                      inStock: _inStock(variants), onImage: true),
                ),
              ],
            ),
            const SizedBox(width: 10),

            /// ManufacturerProduct Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 8, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title — reserves two lines, same contract as the grid
                    /// variant above. `maxLines: 2` alone only CAPS the name; a
                    /// one-line name still collapsed the block and pulled the
                    /// price row and attributes up with it.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: _gridNameBlockHeightOf(context),
                        minWidth: double.infinity,
                      ),
                      child: CustomText(
                        details?.name,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        height: _gridNameLineHeight,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  /// Opens the product-details sheet in owner mode. Per-variant edit,
  /// in/out-of-stock and swipe-to-delete live there now — all three routed to
  /// the manufacturer inventory service.
  void _openDetails(BuildContext context) {
    ProductInventoryBottomSheet.show(
      context,
      product: product,
      isOwner: true,
      onUpdatePrice: getOrPut(() => ManufacturerInventoryController())
          .updateProductVariantPrice,
      onDeleteVariant: (id) => getOrPut(() => ManufacturerInventoryController())
          .deleteInventoryVariant(inventoryId: id),
      // Manufacturer sits on product-service too, so the same
      // `/inventory/stock/toggle-out-of-stock` path applies — but it's routed
      // through the manufacturer controller so ITS lists get the update.
      onToggleStock: (inventoryId, isOutOfStock) =>
          getOrPut(() => ManufacturerInventoryController())
              .toggleVariantOutOfStock(
        inventoryId: inventoryId,
        isOutOfStock: isOutOfStock,
      ),
      onChanged: deleteProductApi,
    );
  }
}
