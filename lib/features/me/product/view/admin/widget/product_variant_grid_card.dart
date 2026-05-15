import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductVariantGridCard extends StatelessWidget {
  final VariantData variantData;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onPreviewTap;

  const ProductVariantGridCard({
    super.key,
    required this.variantData,
    required this.isSelected,
    required this.onTap,
    this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final product = variantData.productInformation;
    final variant = variantData.finalVariant;
    final discount = variant.mrp > 0
        ? ((variant.mrp - variant.sellingPrice) / variant.mrp * 100).round()
        : 0;

    final imageUrl = product.media.isNotEmpty && product.media.first.isNotEmpty
        ? product.media.first
        : (variant.mediaRelatedToVarient.isNotEmpty &&
                variant.mediaRelatedToVarient.first.isNotEmpty
            ? variant.mediaRelatedToVarient.first
            : '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Product image
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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

                // Selection circle (top-right)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.greyE5,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: AppColors.white, size: 16)
                        : null,
                  ),
                ),

                // Eye/preview button (bottom-right)
                if (onPreviewTap != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onPreviewTap,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility_outlined,
                          color: AppColors.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 9.0, vertical: SizeConfig.size6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    product.name,
                    fontSize: SizeConfig.small,
                    maxLines: 1,
                    color: AppColors.mainTextColor,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  PriceRow(
                    sellingPrice:
                        '\u20b9${variant.sellingPrice.toStringAsFixed(0)}',
                    mrp: '\u20b9${variant.mrp.toStringAsFixed(0)}',
                    discount: '$discount% off',
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size4),
          ],
        ),
      ),
    );
  }
}
