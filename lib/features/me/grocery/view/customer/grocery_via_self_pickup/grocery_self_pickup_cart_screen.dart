import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Multi-store grocery cart (Zomato-style). One card per store, each with its
/// own product list + Checkout button; a "Checkout All" bar appears when there
/// is more than one store. Each store checks out as its own order.
class GrocerySelfPickUpCartScreen extends StatelessWidget {
  const GrocerySelfPickUpCartScreen({super.key});

  static const Color _primary = AppColors.primaryColor;
  static const Color _primaryDeep = AppColors.blue5CAF;

  static const List<Color> _cardColors = [
    Color(0xFFEFF6FF),
    Color(0xFFF6F0FF),
    Color(0xFFFFF5EC),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GrocerySelfPickupConsumerController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.mainTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Obx(() {
          final _ = controller.selectedGroceriesVariants.length; // subscribe
          final n = controller.storeCount;
          return CustomText(
            n > 1 ? 'Your Carts ($n)' : 'Your Cart',
            fontSize: SizeConfig.extraLarge,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          );
        }),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.appBackgroundColor, height: 1),
        ),
      ),
      body: Obx(() {
        // Subscribe to both the item list and quantities so the cards +
        // per-store totals repaint on every add / remove / +/- tap.
        final _ = controller.cartQuantities.length;
        final __ = controller.selectedGroceriesVariants.length;

        if (controller.isEmpty) return _emptyState();

        final keys = controller.storeKeys;
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: keys.length,
                padding: EdgeInsets.all(SizeConfig.paddingM),
                itemBuilder: (context, index) => _StoreCard(
                  controller: controller,
                  businessId: keys[index],
                  bgColor: _cardColors[index % _cardColors.length],
                ),
              ),
            ),
            _PlaceOrderBar(controller: controller),
          ],
        );
      }),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.greyCA),
          const SizedBox(height: 16),
          CustomText(
            AppStrings.groceryViewNoItemsSelfPickup.tr,
            fontSize: SizeConfig.large,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  // Shared gradient primary checkout button.
  static Widget checkoutButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primaryDeep, _primary]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STORE CARD — header + product list + per-store checkout footer
// ═══════════════════════════════════════════════════════════════════

class _StoreCard extends StatelessWidget {
  final GrocerySelfPickupConsumerController controller;
  final String businessId;
  final Color bgColor;

  const _StoreCard({
    required this.controller,
    required this.businessId,
    required this.bgColor,
  });

  Map<String, String> get _info => controller.storeInfoOf(businessId);

  List<ProductVariants> get _items => controller.variantsOf(businessId);

  double _calcAverageDiscount(List<ProductVariants> items) {
    double total = 0;
    int count = 0;
    for (var v in items) {
      final pricing = v.pricing;
      if (pricing == null || pricing.isEmpty) continue;
      final mrp = (pricing.first.mrp ?? 0).toDouble();
      final sp = (pricing.first.sellingPrice ?? 0).toDouble();
      if (mrp <= 0 || sp <= 0 || sp >= mrp) continue;
      total += ((mrp - sp) / mrp) * 100;
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final businessName =
        _info['businessName']?.isNotEmpty == true
            ? _info['businessName']!
            : AppStrings.groceryViewUnknownStore.tr;
    final businessLogo = _info['logo'] ?? '';
    final businessAddress = _info['address'] ?? '';
    final averageDiscount = _calcAverageDiscount(items);

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(businessName, businessLogo, averageDiscount),
            if (businessAddress.isNotEmpty) _buildAddressRow(businessAddress),
            ...List.generate(items.length, (i) {
              final v = items[i];
              final fallbackImage = controller.cartProductImages[v.sId] ?? '';
              return _ProductRow(
                variant: v,
                fallbackImage: fallbackImage,
                controller: controller,
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String? get _distanceLabel {
    final lat = double.tryParse(_info['lat'] ?? '') ?? 0.0;
    final lng = double.tryParse(_info['lng'] ?? '') ?? 0.0;
    if (lat == 0 && lng == 0) return null;
    final km = calculateDistance(lat, lng);
    if (km == null) return null;
    return '${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} km Away';
  }

  String? get _shopTypeLabel {
    final raw = _info['category'];
    if (raw == null || raw.trim().isEmpty) return null;
    return raw;
  }

  Widget _buildHeader(String name, String logo, double avgDiscount) {
    final distance = _distanceLabel;
    final shopType = _shopTypeLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatarWidget(
            imageUrl: logo,
            size: SizeConfig.size40,
            borderColor: Colors.white,
            borderRadius: SizeConfig.size20,
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  name,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (distance != null || shopType != null) ...[
                  SizedBox(height: SizeConfig.size4),
                  Row(
                    children: [
                      if (distance != null) ...[
                        _DistancePill(label: distance),
                        const SizedBox(width: 6),
                      ],
                      if (shopType != null)
                        Flexible(child: _ShopTypePill(label: shopType)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (avgDiscount > 0) _DiscountRibbon(percent: avgDiscount),
          // Clear this store's cart.
          InkWell(
            onTap: () => controller.clearStore(businessId),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String businessAddress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 12, color: AppColors.secondaryTextColor),
          const SizedBox(width: 3),
          Expanded(
            child: CustomText(
              businessAddress,
              fontSize: 11,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

}

/// Single-column vertical dashed line.
class _VerticalDashedLine extends StatelessWidget {
  final double height;
  const _VerticalDashedLine({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: height,
      child: CustomPaint(painter: _VerticalDashedLinePainter()),
    );
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.greyE5
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    double y = 0;
    while (y < size.height) {
      final endY = (y + _dash).clamp(0.0, size.height);
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, endY),
        paint,
      );
      y += _dash + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter old) => false;
}

class _ShopTypePill extends StatelessWidget {
  final String label;
  const _ShopTypePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8E8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF1FB35A).withValues(alpha: 0.35),
          width: 0.6,
        ),
      ),
      child: CustomText(
        label,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1FB35A),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DistancePill extends StatelessWidget {
  final String label;
  const _DistancePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined,
              size: 12, color: AppColors.secondaryTextColor),
          const SizedBox(width: 3),
          CustomText(
            label,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PRODUCT ROW (no checkbox — every item is part of its store's order)
// ═══════════════════════════════════════════════════════════════════

class _ProductRow extends StatelessWidget {
  final ProductVariants variant;
  final String fallbackImage;
  final GrocerySelfPickupConsumerController controller;

  const _ProductRow({
    required this.variant,
    required this.fallbackImage,
    required this.controller,
  });

  void _handleRemove(BuildContext context) {
    final qty = controller.getQuantity(variant.sId);
    if (qty > 1) {
      controller.removeFromCart(variant);
      return;
    }
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: AppColors.red, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      'Remove from cart?',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomText(
                '"${variant.variantName ?? 'This product'}" will be removed from your cart.',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyE5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: CustomText(
                        'Cancel',
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.removeFromCart(variant);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: CustomText(
                        'Remove',
                        color: AppColors.white,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w800,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final pricing = variant.pricing?.first;
    final sellingPrice = pricing?.sellingPrice ?? 0;
    final mrp = pricing?.mrp ?? 0;
    final hasDiscount = mrp > sellingPrice && mrp != 0 && sellingPrice != 0;
    final discountPct =
        hasDiscount ? (((mrp - sellingPrice) / mrp) * 100).round() : 0;

    final variantImage =
        (variant.images != null && variant.images!.isNotEmpty)
            ? (variant.images!.first.url ?? '')
            : '';
    final imageUrl = variantImage.isNotEmpty ? variantImage : fallbackImage;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.greyE5, width: 0.6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 54,
                height: 54,
                child: imageUrl.isEmpty
                    ? LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (_, __, ___) => LocalAssets(
                          imagePath: AppIconAssets.place_holder_image,
                          boxFix: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  variant.variantName ?? '',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if ((variant.quantity ?? '').isNotEmpty)
                      CustomText(
                        '${variant.quantity}',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryTextColor,
                      ),
                    if ((variant.quantity ?? '').isNotEmpty &&
                        sellingPrice != 0) ...[
                      const SizedBox(width: 6),
                      CustomText(
                        '·',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.greyCA,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (sellingPrice != 0)
                      Flexible(
                        child: CustomText(
                          '₹$sellingPrice/${variant.unit ?? ''}',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
          const SizedBox(width: 10),
          const _VerticalDashedLine(height: 60),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                '₹$sellingPrice',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              if (hasDiscount) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      '₹$mrp',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F8E8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CustomText(
                        '$discountPct% off',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1FB35A),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Obx(() => _QtyStepper(
                    quantity: controller.getQuantity(variant.sId),
                    onAdd: () => controller.addToCart(variant),
                    onRemove: () => _handleRemove(context),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  QTY STEPPER  ( - N + )
// ═══════════════════════════════════════════════════════════════════

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QtyStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.primaryColor.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Icon(
                  quantity == 1 ? Icons.delete_outline : Icons.remove,
                  color:
                      quantity == 1 ? AppColors.red : AppColors.primaryColor,
                  size: 16,
                ),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            alignment: Alignment.center,
            child: CustomText(
              '$quantity',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Icon(Icons.add, size: 16, color: AppColors.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DISCOUNT RIBBON ( top-right of store card )
// ═══════════════════════════════════════════════════════════════════

class _DiscountRibbon extends StatelessWidget {
  final double percent;
  const _DiscountRibbon({required this.percent});

  String get _label {
    final clamped = percent > 99 ? 99 : percent;
    final isWhole = clamped == clamped.roundToDouble();
    return isWhole ? clamped.toStringAsFixed(0) : clamped.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(-0.2, -0.4),
            radius: 1.1,
            colors: [Color(0xFFB5D147), Color(0xFF0D8A47)],
            stops: [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD83D), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15A352).withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_label%',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 1),
                  child: Text(
                    'Off',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'On All Items',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PLACE ORDER BAR — single checkout for the whole cart (all stores).
//  Uses the original bulk-order call, which posts every item and then
//  lands on the Chats → Inquiry tab.
// ═══════════════════════════════════════════════════════════════════

class _PlaceOrderBar extends StatelessWidget {
  final GrocerySelfPickupConsumerController controller;
  const _PlaceOrderBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.cartQuantities.length; // subscribe
      final total = controller.totalSellingPrice;
      final items = controller.totalItemsCount;
      final stores = controller.storeCount;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        stores > 1
                            ? '$items ${items == 1 ? 'item' : 'items'} · $stores stores'
                            : '$items ${items == 1 ? 'item' : 'items'}',
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        '${AppConstants.rupeeSymbol}${total.toStringAsFixed(2)}',
                        fontSize: SizeConfig.extraLarge,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GrocerySelfPickUpCartScreen.checkoutButton(
                    label: AppStrings.groceryViewPlaceOrder.tr,
                    onTap: controller.placeBulkGroceryOrderApi,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
