import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
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
    final price = firstVariant != null ? controller.getPriceDetails(firstVariant.pricing) : null;
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
                              height: 80,
                              width: 80,
                              color: Colors.grey.shade100,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              height: 80,
                              width: 80,
                              boxFix: BoxFit.cover,
                            ),
                          )
                        : LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            height: 80,
                            width: 80,
                            boxFix: BoxFit.cover,
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
                              : AppStrings.medicalProductNameNotAvailable.tr,
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
                                    ? 'â‚¹${price.sellingRange}'
                                    : AppStrings.medicalPriceNotSet.tr,
                                fontSize: SizeConfig.medium,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(width: 8),
                              if (price.mrpRange.isNotEmpty)
                                Flexible(
                                  child: CustomText(
                                    '${AppStrings.medicalMrpRangePrefix.tr} â‚¹${price.mrpRange}',
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
                            AppStrings.medicalPriceNotAvailable,
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
                                '$variantCount ${AppStrings.medicalVariantSingular.tr}',
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

                  // Share + Arrow trailing actions
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _shareProduct,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: LocalAssets(
                              imagePath: AppIconAssets.share_bold,
                              imgColor: AppColors.primaryColor,
                              height: 14,
                              width: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.secondaryTextColor,
                          size: 22,
                        ),
                      ],
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

  /// Opens the native share sheet with the product's BlueEra deep link
  /// and its name.
  Future<void> _shareProduct() async {
    final rawName = medicalProducts.name?.trim() ?? '';
    final name = rawName.isNotEmpty ? rawName : 'this product';
    final shareLink = medicalDeepLink(medicalProductId: medicalProducts.sId);

    await ShareService.instance.openShareSheet(
      text: "Check out $name on BlueEra:\n$shareLink",
      subject: name,
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
      final dateStr = medicalProducts.lastInventoryAddedOrUpdated ?? DateTime.now().toIso8601String();
      final date = DateTime.parse(dateStr);
      return '${AppStrings.medicalUpdatedPrefix.tr} ${DateFormat("d MMM, yyyy").format(date)}';
    } catch (_) {
      return '';
    }
  }
}
