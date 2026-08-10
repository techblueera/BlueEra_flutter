import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/attribute_two_rows.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_inventory_bottom_sheet.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_preview_eye_button.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_share_button.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/product_price_edit_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
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

  // The name always reserves two lines — in BOTH the grid and the list
  // variant — so cards line up even when a name fits on a single line; the
  // spare line falls to the bottom as blank space. Line-height factor kept
  // explicit so the reserved box and the text agree.
  static const double _nameLineHeight = 1.3;

  /// Unscaled two-line height. The baseline [gridCardHeight] is built from;
  /// widgets should prefer [_nameBlockHeightOf], which tracks the text scale.
  static double get _nameBlockHeight => SizeConfig.medium * _nameLineHeight * 2;

  /// Two-line height at the device's CURRENT text scale.
  ///
  /// `fontSize * factor * 2` is only two lines when the text renders at
  /// `fontSize`. Nothing in this app clamps the system font setting, so on a
  /// phone with enlarged text the real lines are taller than the reserved box —
  /// and a `Text` whose box is shorter than its content clips, which is what
  /// ate the second line.
  static double _nameBlockHeightOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(SizeConfig.medium) *
      _nameLineHeight *
      2;

  /// Total height of the grid-style card (`isGridShow: true`), derived from
  /// its content so the home strip and the view-all grid can size their cells
  /// identically without hardcoding a magic number.
  ///
  /// Scaled by the system text setting for the same reason the name block is:
  /// the rail gives the card a TIGHT height, so if the name grows with the
  /// user's font size and this doesn't, the card overflows its own rail.
  /// Read from the platform dispatcher rather than a [MediaQuery] because the
  /// rails ask for this before they have a card context — equivalent here,
  /// since nothing in the app overrides the inherited text scaler.
  static double get gridCardHeight {
    final imageHeight = SizeConfig.size150 - 10;
    const priceRowHeight = 26.0; // FittedBox price row + small buffer
    final textScale =
        WidgetsBinding.instance.platformDispatcher.textScaleFactor;
    return imageHeight +
        SizeConfig.size10 * 2 + // vertical padding around details
        _nameBlockHeight * textScale +
        SizeConfig.size5 + // gap before price
        priceRowHeight;
  }

  /// Whether the product reads as in stock — true when ANY variant is
  /// sellable. One available size still means a customer can buy it, so only a
  /// wholly-flagged product reads as out. An empty variant list says nothing
  /// either way, so it is not marked as out.
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
                    child: ProductPreviewEyeButton(
                      onTap: () => _openDetails(context),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: ProductShareButton(
                      productId: productId,
                      productName: details?.name,
                    ),
                  ),
                  // Stock state on the photo, where the eye lands first when
                  // scanning a rail. Bottom-LEFT: the top corners already carry
                  // the preview and share buttons.
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: StockStatusPill(
                        inStock: _inStock(variants), onImage: true),
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
                  // Product Name — reserves two lines so short and long names
                  // occupy the same height (extra space stays at the bottom of
                  // the card).
                  //
                  // minHeight, NOT a tight height. A tight box is only ever
                  // exactly two lines if the arithmetic matches the rendered
                  // text to the pixel, and it doesn't: the system text scale is
                  // unclamped here, and font metrics round. Whenever the real
                  // two lines came out even slightly taller than the box, the
                  // Text clipped and the second line vanished. A floor reserves
                  // the same space for short names and simply grows instead of
                  // cutting when the text needs more.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: _nameBlockHeightOf(context),
                      minWidth: double.infinity,
                    ),
                    child: CustomText(
                      details?.name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      height: _nameLineHeight,
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
                  child: ProductPreviewEyeButton(
                    onTap: () => _openDetails(context),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: ProductShareButton(
                    productId: productId,
                    productName: details?.name,
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

            /// Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 8, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title — reserves two lines, same contract as the grid
                    /// variant above (see the note there on why this is a
                    /// minHeight rather than a tight box). `maxLines: 2` alone
                    /// only CAPS the name; a one-line name still collapsed the
                    /// block and pulled the price row and attributes up with
                    /// it, so two cards side by side disagreed on where their
                    /// price sat.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: _nameBlockHeightOf(context),
                        minWidth: double.infinity,
                      ),
                      child: CustomText(
                        details?.name,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        height: _nameLineHeight,
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

  /// Opens the product-details sheet in owner mode. Per-variant edit,
  /// in/out-of-stock and swipe-to-delete live there now — the card no longer
  /// carries blunt edit/delete buttons that could only ever target the first
  /// variant.
  void _openDetails(BuildContext context) {
    ProductInventoryBottomSheet.show(
      context,
      product: product,
      isOwner: true,
      onUpdatePrice: onUpdatePrice,
      onChanged: deleteProductApi,
      // Product-service only. The sheet leaves the pill read-only when this
      // isn't supplied, which is what keeps automotive / manufacturer (who
      // reuse the sheet with their own inventory ids) from PATCHing here.
      onToggleStock: (inventoryId, isOutOfStock) =>
          getOrPut(() => InventoryController()).toggleVariantOutOfStock(
        inventoryId: inventoryId,
        isOutOfStock: isOutOfStock,
      ),
    );
  }
}
