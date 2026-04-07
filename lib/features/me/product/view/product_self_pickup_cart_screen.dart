import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.mainTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Obx(() => CustomText(
              'Self Pick-Up (${controller.totalItemsCount})',
              fontSize: SizeConfig.extraLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.appBackgroundColor, height: 1),
        ),
      ),
      bottomNavigationBar: Obx(() {
        if (controller.selectedProductVariants.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bill summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              color: AppColors.white,
              child: Column(
                children: [
                  _BillRow(
                      label: 'Items Total',
                      value:
                          '${AppConstants.rupeeSymbol}${controller.totalMRP.toStringAsFixed(2)}'),
                  if (controller.totalSavings > 0)
                    _BillRow(
                      label: 'Discount',
                      value:
                          '- ${AppConstants.rupeeSymbol}${controller.totalSavings.toStringAsFixed(2)}',
                      valueColor: Colors.green,
                    ),
                  const Divider(height: 16, color: AppColors.greyE5),
                  _BillRow(
                    label: 'Grand Total',
                    value:
                        '${AppConstants.rupeeSymbol}${controller.totalSellingPrice.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            // Place order button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.white,
              child: SafeArea(
                top: false,
                child: InkWell(
                  onTap: controller.isPlaceProductOrderLoading.value
                      ? null
                      : () => controller.placeProductOrderApi(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: controller.isPlaceProductOrderLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                'Place Order',
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 8),
                              CustomText(
                                '${AppConstants.rupeeSymbol}${controller.totalSellingPrice.toStringAsFixed(2)}',
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
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

        // Group by business
        final Map<String, List<GetProductData>> grouped = {};
        for (final p in items) {
          final id = _variantIdOf(p);
          final info = id == null ? null : controller.cartBusinessInfo[id];
          final bId = info?['businessId'] ?? 'unknown';
          grouped.putIfAbsent(bId, () => []).add(p);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped.entries.elementAt(index);
            final groupItems = entry.value;
            final firstId = _variantIdOf(groupItems.first);
            final businessInfo = firstId == null
                ? <String, String>{}
                : (controller.cartBusinessInfo[firstId] ?? {});

            return _StoreGroupCard(
              businessName: businessInfo['businessName'] ?? 'Unknown Store',
              businessLogo: businessInfo['logo'] ?? '',
              businessAddress: businessInfo['address'] ?? '',
              items: groupItems,
              controller: controller,
              variantIdOf: _variantIdOf,
            );
          },
        );
      }),
    );
  }
}

// ─── Bill Row ────────────────────────────────────────────────────────────────

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _BillRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            label,
            fontSize: isBold ? SizeConfig.large : SizeConfig.medium,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color:
                isBold ? AppColors.mainTextColor : AppColors.secondaryTextColor,
          ),
          CustomText(
            value,
            fontSize: isBold ? SizeConfig.large : SizeConfig.medium,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ??
                (isBold
                    ? AppColors.mainTextColor
                    : AppColors.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}

// ─── Store Group Card ────────────────────────────────────────────────────────

class _StoreGroupCard extends StatelessWidget {
  final String businessName;
  final String businessLogo;
  final String businessAddress;
  final List<GetProductData> items;
  final ProductSelfPickupController controller;
  final String? Function(GetProductData) variantIdOf;

  const _StoreGroupCard({
    required this.businessName,
    required this.businessLogo,
    required this.businessAddress,
    required this.items,
    required this.controller,
    required this.variantIdOf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CachedAvatarWidget(
                  imageUrl: businessLogo,
                  size: 40,
                  borderColor: AppColors.greyE5,
                  borderRadius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        businessName,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (businessAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        CustomText(
                          businessAddress,
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Item count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomText(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.greyE5),
          // Product items
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

// ─── Product Row ─────────────────────────────────────────────────────────────

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
    final img =
        (details?.media.isNotEmpty ?? false) ? details!.media.first : '';
    final sellingPrice = firstVariant?.sellingPrice ?? 0;
    final mrp = firstVariant?.mrp ?? 0;
    final id = variantIdOf(product);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Name & price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  details?.name ?? '',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CustomText(
                      '${AppConstants.rupeeSymbol}$sellingPrice',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    if (mrp > sellingPrice) ...[
                      const SizedBox(width: 6),
                      CustomText(
                        '${AppConstants.rupeeSymbol}$mrp',
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor,
                      ),
                      const SizedBox(width: 6),
                      CustomText(
                        '${((mrp - sellingPrice) / mrp * 100).toStringAsFixed(0)}% off',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty stepper
          Obx(() {
            final qty = controller.getQuantity(id);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => controller.removeFromCart(product),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        qty == 1 ? Icons.delete_outline : Icons.remove,
                        size: 16,
                        color: qty == 1
                            ? Colors.red
                            : AppColors.primaryColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CustomText(
                      '$qty',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  InkWell(
                    onTap: () => controller.addToCart(product),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.add,
                          size: 16, color: AppColors.primaryColor),
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

  Widget _placeholder() {
    return Container(
      color: AppColors.greyE4,
      child: Center(
        child: LocalAssets(
          imagePath: AppIconAssets.place_holder_image,
          boxFix: BoxFit.cover,
          width: 56,
          height: 56,
        ),
      ),
    );
  }
}
