import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/product_catalog_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/product_select_plus_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One card per PRODUCT in the admin product-selection grid. Visually
/// mirrors the grocery selection card (image hero + name + price + a
/// full-width Add/Added button), but the button opens the variant picker
/// sheet — products carry multiple variants, so selection happens there
/// (food flow). The button reflects how many variants are in the cart.
class ProductSelectionProductCard extends StatelessWidget {
  final Product product;
  final ProductController controller;
  final void Function(Product) onShowVariants;

  const ProductSelectionProductCard({
    super.key,
    required this.product,
    required this.controller,
    required this.onShowVariants,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.media.isNotEmpty ? product.media.first : '';
    final firstVariant =
        product.variants.isNotEmpty ? product.variants.first : null;
    final selling = firstVariant?.sellingPrice ?? 0;
    final mrp = firstVariant?.mrp ?? 0;
    final discount = (mrp > 0 && selling > 0 && selling < mrp)
        ? ((mrp - selling) / mrp * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: SizedBox(
                  height: SizeConfig.size140,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
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
              // Top-right add button (replaces the old full-width "Add").
              Positioned(
                top: SizeConfig.size8,
                right: SizeConfig.size8,
                child: Obx(() {
                  final count =
                      controller.selectedVariantCountForProduct(product.id);
                  return ProductSelectPlusButton(
                    added: count > 0,
                    count: count,
                    onTap: () => onShowVariants(product),
                  );
                }),
              ),
            ],
          ),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 8.0, vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reserve two lines so every card is the same height
                // regardless of name length.
                SizedBox(
                  height: SizeConfig.small * 1.3 * 2,
                  child: CustomText(
                    product.name,
                    fontSize: SizeConfig.small,
                    height: 1.3,
                    maxLines: 2,
                    color: AppColors.mainTextColor,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(width: 0.5, color: AppColors.greyE5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: CustomText(
                    '${product.variants.length} variants',
                    fontSize: 11,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: '₹${selling.toStringAsFixed(0)}',
                  mrp: '₹${mrp.toStringAsFixed(0)}',
                  discount: '$discount% off',
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size4),
        ],
      ),
    );
  }
}
