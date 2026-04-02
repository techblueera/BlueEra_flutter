import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductFloatingCart extends StatelessWidget {
  final List<VariantData> selectedProducts;
  final VoidCallback onTap;

  const ProductFloatingCart({
    super.key,
    required this.selectedProducts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedProducts.isEmpty) return const SizedBox.shrink();

    final displayImages = selectedProducts.take(3).map((p) {
      if (p.productInformation.media.isNotEmpty &&
          p.productInformation.media.first.isNotEmpty) {
        return p.productInformation.media.first;
      } else if (p.finalVariant.mediaRelatedToVarient.isNotEmpty &&
          p.finalVariant.mediaRelatedToVarient.first.isNotEmpty) {
        return p.finalVariant.mediaRelatedToVarient.first;
      }
      return null;
    }).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size20),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Overlapping product images
            SizedBox(
              width: _calculateImagesWidth(displayImages.length),
              height: 36,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(displayImages.length, (index) {
                  return Positioned(
                    left: index * 22.0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: displayImages[index] != null
                            ? CachedNetworkImage(
                                imageUrl: displayImages[index]!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: Colors.grey.shade300,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey.shade300,
                                  child: LocalAssets(
                                    imagePath:
                                        AppIconAssets.place_holder_image,
                                    boxFix: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: LocalAssets(
                                  imagePath:
                                      AppIconAssets.place_holder_image,
                                  boxFix: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            SizedBox(width: SizeConfig.size10),

            // Text column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  'View cart',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                CustomText(
                  '${selectedProducts.length} Items',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ],
            ),

            SizedBox(width: SizeConfig.size8),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateImagesWidth(int count) {
    if (count == 0) return 0;
    // First image = 36, each additional overlaps by 22
    return 36.0 + (count - 1) * 22.0;
  }
}
