import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_attribute_two_rows.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_inventory_bottom_sheet.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_preview_eye_button.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/product_price_edit_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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

    return GestureDetector(
      onTap: () => ProductInventoryBottomSheet.show(context, product: product),
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
                  // Owner card — price-edit + delete shortcuts.
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _deleteButton(context),
                        const SizedBox(width: 6),
                        _editButton(context),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: ProductPreviewEyeButton(
                      onTap: () => ProductInventoryBottomSheet.show(context,
                          product: product),
                    ),
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
                  // AutomotiveProduct Name — fixed two-line block so short and long
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
                    onTap: () => ProductInventoryBottomSheet.show(context,
                        product: product),
                  ),
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
                        InkWell(
                          onTap: () => _confirmAndDelete(context),
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ],
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

  // Opens the price-edit sheet. Updates go through the product-service
  // inventory endpoint by default; callers (earn screens) can override.
  void _onEditTap(BuildContext context) {
    ProductPriceEditSheet.show(
      context: context,
      product: product,
      onUpdate: onUpdatePrice ??
          getOrPut(() => AutomotiveInventoryController()).updateProductVariantPrice,
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

  Widget _deleteButton(BuildContext context) {
    return InkWell(
      onTap: () => _confirmAndDelete(context),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.red, width: 1.0),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: AppColors.red, size: 14),
      ),
    );
  }

  /// Confirms, then deletes this product's inventory variant via
  /// `DELETE automotive-service/api/inventory/{inventoryId}`. On success the
  /// controller drops it from the grid and the parent's [deleteProductApi] hook
  /// fires so its own list can refresh too.
  Future<void> _confirmAndDelete(BuildContext context) async {
    final variants = product.product.sellerClassification?.variants ?? [];
    final inventoryId = variants.isEmpty
        ? ''
        : (variants.first.inventoryId.isNotEmpty
            ? variants.first.inventoryId
            : variants.first.id);
    if (inventoryId.isEmpty) {
      commonSnackBar(message: "This product can't be deleted.");
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText('Delete product?',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor),
        content: CustomText(
          '"${product.product.details?.name ?? 'This item'}" will be '
          "permanently removed from your inventory. This can't be undone.",
          fontSize: 13,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: CustomText('Cancel',
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w700),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: CustomText('Delete',
                color: AppColors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    AppLoader.show();
    final ok = await getOrPut(() => AutomotiveInventoryController())
        .deleteInventoryVariant(inventoryId: inventoryId);
    AppLoader.hide();

    if (ok) {
      deleteProductApi(); // let the hosting screen refresh its own list too
      commonSnackBar(message: 'Product deleted.');
    } else {
      commonSnackBar(message: 'Could not delete the product.');
    }
  }

}
