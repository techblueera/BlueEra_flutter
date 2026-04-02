import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/model/images.dart';
import '../../model/my_medical_products_response.dart';

class MedicalProductCard extends StatelessWidget {
  final Products medicalProducts;
  final String? categoryId;

  const MedicalProductCard({
    Key? key,
    required this.medicalProducts,
    this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => MedicalController());
    final variantCount = medicalProducts.variants?.length ?? 0;
    final firstVariant = medicalProducts.variants?.firstOrNull;
    final price = firstVariant != null
        ? controller.getPriceDetails(firstVariant.pricing)
        : null;
    final imageUrl = medicalProducts.images?.firstOrNull?.url;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: InkWell(
        onTap: () => _navigateToVariants(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Image + Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 80, width: 80,
                              color: Colors.grey.shade100,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              height: 80, width: 80, boxFix: BoxFit.cover,
                            ),
                          )
                        : LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            height: 80, width: 80, boxFix: BoxFit.cover,
                          ),
                  ),
                  SizedBox(width: SizeConfig.size12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        CustomText(
                          (medicalProducts.name != null && medicalProducts.name!.isNotEmpty)
                              ? medicalProducts.name!
                              : 'Product name not available',
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        SizedBox(height: 6),

                        // Price row
                        if (price != null)
                          Row(
                            children: [
                              CustomText(
                                (price.sellingRange.isNotEmpty)
                                    ? '₹${price.sellingRange}'
                                    : 'Price not set',
                                fontSize: SizeConfig.medium,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(width: 8),
                              if (price.mrpRange.isNotEmpty)
                                Flexible(
                                  child: CustomText(
                                    'MRP ₹${price.mrpRange}',
                                    fontSize: SizeConfig.extraSmall,
                                    color: AppColors.grayText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          )
                        else
                          CustomText(
                            'Price not available',
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                        SizedBox(height: 6),

                        // Variant count + Last update
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CustomText(
                                '$variantCount Variant${variantCount != 1 ? 's' : ''}',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: CustomText(
                                _formatLastUpdate(),
                                fontSize: 10,
                                color: AppColors.secondaryTextColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondaryTextColor,
                      size: 22,
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  void _navigateToVariants() {
    Images? productImage;
    if (medicalProducts.images != null && medicalProducts.images!.isNotEmpty) {
      productImage = medicalProducts.images![0];
    }

    final variants = medicalProducts.variants ?? [];

    for (final variant in variants) {
      if (productImage != null) {
        if (variant.images == null) {
          variant.images = [productImage];
        } else if (variant.images!.isEmpty) {
          variant.images!.add(productImage);
        }
      }
    }

    Get.toNamed(
      RouteHelper.getMyMedicalVariantScreenRoute(),
      arguments: {
        ApiKeys.argVariants: variants,
        ApiKeys.argIsShowInGrid: true,
        ApiKeys.argCategoryId: categoryId,
      },
    );
  }

  String _formatLastUpdate() {
    try {
      final dateStr = medicalProducts.lastInventoryAddedOrUpdated ??
          DateTime.now().toIso8601String();
      final date = DateTime.parse(dateStr);
      return 'Updated ${DateFormat("d MMM, yyyy").format(date)}';
    } catch (_) {
      return '';
    }
  }
}