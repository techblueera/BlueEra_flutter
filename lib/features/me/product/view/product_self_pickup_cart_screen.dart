import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Cart detail screen for the product self-pickup flow.
/// Items are grouped by store (using
/// [ProductSelfPickupController.cartBusinessInfo]).
class ProductSelfPickUpCartScreen extends StatelessWidget {
  const ProductSelfPickUpCartScreen({super.key});

  String? _variantIdOf(GetProductData product) {
    final variants = product.product.sellerClassification?.variants;
    if (variants == null || variants.isEmpty) return null;
    final id = variants.first.id;
    return id.isEmpty ? null : id;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductSelfPickupController>();

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: 'Self Pick-Up',
      ),
      body: Obx(() {
        final items = controller.selectedProductVariants;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 64, color: AppColors.greyCA),
                const SizedBox(height: 16),
                CustomText(
                  'No items in self pick-up',
                  fontSize: SizeConfig.large,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          );
        }

        // Group by business.
        final Map<String, List<GetProductData>> grouped = {};
        for (final p in items) {
          final id = _variantIdOf(p);
          final info = id == null ? null : controller.cartBusinessInfo[id];
          final bId = info?['businessId'] ?? 'unknown';
          grouped.putIfAbsent(bId, () => []).add(p);
        }

        return ListView(
          padding: EdgeInsets.all(SizeConfig.size10),
          children: grouped.entries.map((entry) {
            final groupItems = entry.value;
            final firstId = _variantIdOf(groupItems.first);
            final businessInfo = firstId == null
                ? <String, String>{}
                : (controller.cartBusinessInfo[firstId] ?? {});
            return _StoreGroupCard(
              businessName: businessInfo['businessName'] ?? 'Unknown Store',
              businessLogo: businessInfo['logo'] ?? '',
              items: groupItems,
              controller: controller,
              variantIdOf: _variantIdOf,
            );
          }).toList(),
        );
      }),
    );
  }
}

class _StoreGroupCard extends StatelessWidget {
  final String businessName;
  final String businessLogo;
  final List<GetProductData> items;
  final ProductSelfPickupController controller;
  final String? Function(GetProductData) variantIdOf;

  const _StoreGroupCard({
    required this.businessName,
    required this.businessLogo,
    required this.items,
    required this.controller,
    required this.variantIdOf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CachedAvatarWidget(
                imageUrl: businessLogo,
                size: SizeConfig.size40,
                borderColor: Colors.white,
                borderRadius: SizeConfig.size20,
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: CustomText(
                  businessName,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.greyE5, height: 20),
          ...items.map(
            (p) => _ProductRow(
              product: p,
              controller: controller,
              variantIdOf: variantIdOf,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final GetProductData product;
  final ProductSelfPickupController controller;
  final String? Function(GetProductData) variantIdOf;

  const _ProductRow({
    required this.product,
    required this.controller,
    required this.variantIdOf,
  });

  @override
  Widget build(BuildContext context) {
    final details = product.product.details;
    final variants = product.product.sellerClassification?.variants ?? [];
    final firstVariant = variants.isNotEmpty ? variants.first : null;
    final img = (details?.media.isNotEmpty ?? false) ? details!.media.first : '';
    final sellingPrice = firstVariant?.sellingPrice ?? 0;
    final mrp = firstVariant?.mrp ?? 0;
    final id = variantIdOf(product);

    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 50,
              height: 50,
              child: img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
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
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  details?.name ?? '',
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    CustomText(
                      '${AppConstants.rupeeSymbol}$sellingPrice',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                    ),
                    if (mrp > sellingPrice) ...[
                      const SizedBox(width: 6),
                      CustomText(
                        '${AppConstants.rupeeSymbol}$mrp',
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Qty stepper
          Obx(() {
            final qty = controller.getQuantity(id);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyE5),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => controller.removeFromCart(product),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(Icons.remove,
                          size: 14, color: AppColors.secondaryTextColor),
                    ),
                  ),
                  CustomText(
                    '$qty',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  InkWell(
                    onTap: () => controller.addToCart(product),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(Icons.add,
                          size: 14, color: AppColors.secondaryTextColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
