import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_attribute_two_rows.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_inventory_bottom_sheet.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_preview_eye_button.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/product_price_edit_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class AutomotiveAdminProductCard extends StatelessWidget {
  final GetProductData product;
  final VoidCallback deleteProductApi;
  final double? width;
  final bool isGridShow;
  final bool showAttributes;

  /// AutomotivePrice-update service for the edit sheet. Defaults to the product-service
  /// inventory endpoint ([AutomotiveInventoryController]); the home-made-product (earn)
  /// screens pass [EarnServiceController.updateProductVariantPrice] instead.
  final PriceUpdateCallback? onUpdatePrice;

  const AutomotiveAdminProductCard({
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

  /// Total height of the grid-style card (`isGridShow: true`), derived from
  /// its content so the home strip and the view-all grid can size their cells
  /// identically without hardcoding a magic number.
  ///
  /// Text-scaled: the rail gives the card a TIGHT height, so if the name grows
  /// with the user's font size and this doesn't, the card overflows its rail.
  static double get gridCardHeight {
    final imageHeight = SizeConfig.size150 - 10;
    const priceRowHeight = 26.0; // FittedBox price row + small buffer
    final textScale =
        WidgetsBinding.instance.platformDispatcher.textScaleFactor;
    return imageHeight +
        SizeConfig.size10 * 2 + // vertical padding around details
        _gridNameBlockHeight * textScale +
        SizeConfig.size5 + // gap before price
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
      child: (isGridShow) ? Container(
        width: width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AutomotiveProduct Image
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

            // AutomotiveProduct Details
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size10,
                  horizontal: SizeConfig.size8
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AutomotiveProduct Name — reserves two lines so short and
                  // long names occupy the same height (extra space stays at
                  // the bottom of the card).
                  //
                  // minHeight, NOT a tight height: a tight box clips whenever
                  // the rendered two lines come out taller than the arithmetic
                  // predicts (unclamped system text scale, font-metric
                  // rounding), which silently ate the second line.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: _gridNameBlockHeightOf(context),
                      minWidth: double.infinity,
                    ),
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

                  // AutomotivePrice Row
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
                    AutomotiveAttributeRows(attributeMap: uniqueAttributes),

                  // const SizedBox(height: 6),
                  //
                  // // Share AutomotiveProduct
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
            /// AutomotiveProduct Image
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

            /// AutomotiveProduct Details
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

                    /// AutomotivePrice Row
                    PriceRow(
                      sellingPrice: '\u20B9${variants[0].sellingPrice}',
                      mrp: '\u20B9${variants[0].mrp}',
                      discount: "${calculateDiscount('${variants[0].sellingPrice}', '${variants[0].mrp}')}% OFF",
                    ),
                    SizedBox(height: SizeConfig.size4),

                    AutomotiveAttributeRows(attributeMap: uniqueAttributes),

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
  /// in/out-of-stock and swipe-to-delete live there now — all routed to the
  /// automotive inventory service.
  void _openDetails(BuildContext context) {
    ProductInventoryBottomSheet.show(
      context,
      product: product,
      isOwner: true,
      onUpdatePrice: onUpdatePrice ??
          getOrPut(() => AutomotiveInventoryController())
              .updateProductVariantPrice,
      onDeleteVariant: (id) => getOrPut(() => AutomotiveInventoryController())
          .deleteInventoryVariant(inventoryId: id),
      // Automotive FLIPS rather than sets, so the sheet's `isOutOfStock`
      // argument is only its expectation — dropped here, and the server's
      // actual value is returned for the sheet to reconcile against. The host
      // matters: grocery- and product-service expose this identical sub-path,
      // and aiming at the wrong one marks another catalogue's items sold out
      // with no error at all.
      onToggleStock: (inventoryId, _) =>
          getOrPut(() => AutomotiveInventoryController())
              .flipVariantOutOfStock(inventoryId: inventoryId),
      onChanged: deleteProductApi,
    );
  }
}
