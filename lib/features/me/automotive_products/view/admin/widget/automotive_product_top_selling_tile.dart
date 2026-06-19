import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_attribute_two_rows.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_preview_eye_button.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Shared product image widget with optional cart overlay.
class AutomotiveProductTopSellingImage extends StatelessWidget {
  final GetProductData product;

  /// Optional cart overlay (add/remove button built externally).
  final Widget? cartOverlay;

  /// When set, a small "view" eye button is shown (bottom-right) so users know
  /// the card opens the product detail bottom sheet.
  final VoidCallback? onPreviewTap;

  const AutomotiveProductTopSellingImage({
    super.key,
    required this.product,
    this.cartOverlay,
    this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final media = product.product.details?.media ?? [];
    final hasImage = media.isNotEmpty;
    final imageUrl = hasImage ? media.first : '';

    final imageChild = ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: hasImage && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.cover,
              ),
            )
          : LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
            ),
    );

    if (cartOverlay == null && onPreviewTap == null) return imageChild;

    return Stack(
      children: [
        Positioned.fill(child: imageChild),
        if (cartOverlay != null)
          Positioned(
            top: 0,
            right: 0,
            child: cartOverlay!,
          ),
        if (onPreviewTap != null)
          Positioned(
            top: 6,
            left: 6,
            child: ProductPreviewEyeButton(onTap: onPreviewTap!),
          ),
      ],
    );
  }
}

/// Shared product-info section (below the image) used by both the horizontal
/// top-selling list on [AutomotiveVisitProductStoreDetailsScreen] and the grid on
/// the admin/customer `AllTopSellingProductsScreen` pages.
///
/// Tapping the section opens a [SimpleDialog] with the full details.
class AutomotiveProductTopSellingInfoSection extends StatelessWidget {
  final GetProductData product;

  const AutomotiveProductTopSellingInfoSection({
    super.key,
    required this.product,
  });

  /// Builds the unique-attributes map from the product variants.
  Map<String, List<dynamic>> _buildUniqueAttributes() {
    final variants =
        product.product.sellerClassification?.variants ?? [];
    final Map<String, List<dynamic>> uniqueAttributes = {};
    final firstKeys = <String>[];

    for (var v in variants) {
      for (var key in v.attributes.keys) {
        if (!firstKeys.contains(key)) firstKeys.add(key);
        if (firstKeys.length == 1) break;
      }
      if (firstKeys.length == 1) break;
    }

    for (var key in firstKeys) {
      uniqueAttributes[key] = [];
      for (var v in variants) {
        final value = v.attributes[key];
        if (value == null) continue;
        if (key == 'color' && value is Map<String, dynamic>) {
          final colorMap = {
            'color_name': value['color_name'] ?? '',
            'color_code': value['color_code'] ?? '',
          };
          if (!uniqueAttributes[key]!.any((e) =>
              e is Map &&
              e['color_name'] == colorMap['color_name'] &&
              e['color_code'] == colorMap['color_code'])) {
            uniqueAttributes[key]!.add(colorMap);
          }
        } else {
          if (!uniqueAttributes[key]!.contains(value)) {
            uniqueAttributes[key]!.add(value);
          }
        }
      }
    }

    return uniqueAttributes;
  }

  @override
  Widget build(BuildContext context) {
    final details = product.product.details;
    final variants =
        product.product.sellerClassification?.variants ?? [];
    final uniqueAttributes = _buildUniqueAttributes();

    return GestureDetector(
      onTap: () => _showDetailsDialog(context, details, variants,
          uniqueAttributes),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 9.0, vertical: SizeConfig.size6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              details?.name ?? '',
              fontSize: SizeConfig.medium,
              maxLines: 2,
              color: AppColors.mainTextColor,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: SizeConfig.size6),
            if (variants.isNotEmpty)
              PriceRow(
                sellingPrice:
                    '${AppConstants.rupeeSymbol}${variants[0].sellingPrice}',
                mrp:
                    '${AppConstants.rupeeSymbol}${variants[0].mrp}',
                discount:
                    "${calculateDiscount('${variants[0].sellingPrice}', '${variants[0].mrp}')}% OFF",
              ),
            AutomotiveAttributeRows(attributeMap: uniqueAttributes),
            SizedBox(height: SizeConfig.size4),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    ProductDetails? details,
    List<Variant> variants,
    Map<String, List<dynamic>> uniqueAttributes,
  ) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        contentPadding: const EdgeInsets.all(16),
        children: [
          CustomText(
            details?.name ?? '',
            fontSize: 14,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          if (variants.isNotEmpty)
            PriceRow(
              sellingPrice:
                  '${AppConstants.rupeeSymbol}${variants[0].sellingPrice}',
              mrp:
                  '${AppConstants.rupeeSymbol}${variants[0].mrp}',
              discount:
                  "${calculateDiscount('${variants[0].sellingPrice}', '${variants[0].mrp}')}% OFF",
            ),
          const SizedBox(height: 8),
          AutomotiveAttributeRows(attributeMap: uniqueAttributes),
        ],
      ),
    );
  }
}
