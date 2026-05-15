import 'package:BlueEra/core/constants/app_colors.dart';
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

class GrocerySelfPickUpCartScreen extends StatefulWidget {
  const GrocerySelfPickUpCartScreen({super.key});

  @override
  State<GrocerySelfPickUpCartScreen> createState() =>
      _GrocerySelfPickUpCartScreenState();
}

class _GrocerySelfPickUpCartScreenState
    extends State<GrocerySelfPickUpCartScreen> {
  static const List<Color> _cardColors = [
    Color(0xFFEFF6FF),
    Color(0xFFF6F0FF),
    Color(0xFFFFF5EC),
  ];

  /// Stores the user has opted-into for the order.
  final RxSet<String> selectedBusinessIds = <String>{}.obs;

  /// Variants the user wants in the order — defaulted to "all" on first
  /// build, then user can deselect individual rows from the store card.
  final RxSet<String> selectedVariantIds = <String>{}.obs;

  bool _initialized = false;

  Map<String, List<ProductVariants>> _groupByBusiness(
      GrocerySelfPickupConsumerController controller) {
    final Map<String, List<ProductVariants>> grouped = {};
    for (var variant in controller.selectedGroceriesVariants) {
      final info = controller.cartBusinessInfo[variant.sId];
      final businessId = info?['businessId'] ?? 'unknown';
      grouped.putIfAbsent(businessId, () => []).add(variant);
    }
    if (!_initialized && grouped.isNotEmpty) {
      selectedBusinessIds.addAll(grouped.keys);
      for (final v in controller.selectedGroceriesVariants) {
        final id = v.sId;
        if (id != null) selectedVariantIds.add(id);
      }
      _initialized = true;
    }
    return grouped;
  }

  double _calcTotal(List<ProductVariants> items,
      GrocerySelfPickupConsumerController controller) {
    double total = 0;
    for (var v in items) {
      if (!selectedVariantIds.contains(v.sId)) continue;
      int qty = controller.getQuantity(v.sId);
      double sp =
          double.tryParse(v.pricing?.first.sellingPrice.toString() ?? '0') ?? 0;
      total += sp * qty;
    }
    return total;
  }

  int _calcItemCount(List<ProductVariants> items,
      GrocerySelfPickupConsumerController controller) {
    int count = 0;
    for (var v in items) {
      if (!selectedVariantIds.contains(v.sId)) continue;
      count += controller.getQuantity(v.sId);
    }
    return count;
  }

  /// Average discount % across the store's variants — used by the corner
  /// ribbon. Variants with no MRP / no selling price are skipped.
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

  void _toggleVariant(String? id) {
    if (id == null) return;
    if (selectedVariantIds.contains(id)) {
      selectedVariantIds.remove(id);
    } else {
      selectedVariantIds.add(id);
    }
  }

  /// Strip variants the user has unchecked (per-product OR whole-shop)
  /// from the controller's cart, then place the order. Without this the
  /// API would receive every variant in the cart regardless of checkbox
  /// state.
  void _placeOrder(GrocerySelfPickupConsumerController controller,
      Map<String, List<ProductVariants>> grouped) {
    final toDrop = <ProductVariants>[];
    for (final entry in grouped.entries) {
      final shopChecked = selectedBusinessIds.contains(entry.key);
      for (final v in entry.value) {
        final variantChecked = selectedVariantIds.contains(v.sId);
        if (!shopChecked || !variantChecked) toDrop.add(v);
      }
    }

    // removeFromCart decrements by 1 per call; loop until qty hits 0 so
    // the variant is fully evicted before the order goes out.
    for (final v in toDrop) {
      while (controller.getQuantity(v.sId) > 0) {
        controller.removeFromCart(v);
      }
    }

    controller.placeBulkGroceryOrderApi();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GrocerySelfPickupConsumerController>();

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
        title: CustomText(
          AppStrings.groceryViewSelfPickUp.tr,
          fontSize: SizeConfig.extraLarge,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.appBackgroundColor, height: 1),
        ),
      ),
      body: Obx(() {
        final variants = controller.selectedGroceriesVariants;

        if (variants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 64, color: AppColors.greyCA),
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

        final grouped = _groupByBusiness(controller);
        final businessIds = grouped.keys.toList();

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: businessIds.length,
                padding: EdgeInsets.all(SizeConfig.paddingM),
                itemBuilder: (context, index) {
                  final businessId = businessIds[index];
                  final items = grouped[businessId]!;
                  final businessInfo =
                      controller.cartBusinessInfo[items.first.sId] ?? {};
                  final Color bgColor =
                      _cardColors[index % _cardColors.length];

                  return _StoreCard(
                    businessName: businessInfo['businessName'] ??
                        AppStrings.groceryViewUnknownStore.tr,
                    businessLogo: businessInfo['logo'] ?? '',
                    businessAddress: businessInfo['address'] ?? '',
                    items: items,
                    controller: controller,
                    bgColor: bgColor,
                    selectedVariantIds: selectedVariantIds,
                    onVariantToggle: _toggleVariant,
                    averageDiscount: _calcAverageDiscount(items),
                  );
                },
              ),
            ),
            _BottomSummaryBar(
              grouped: grouped,
              controller: controller,
              calcTotal: _calcTotal,
              calcItemCount: _calcItemCount,
              selectedBusinessIds: selectedBusinessIds,
              onPlaceOrder: () => _placeOrder(controller, grouped),
            ),
          ],
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STORE CARD — header + inline product list
// ═══════════════════════════════════════════════════════════════════

class _StoreCard extends StatelessWidget {
  final String businessName;
  final String businessLogo;
  final String businessAddress;
  final List<ProductVariants> items;
  final GrocerySelfPickupConsumerController controller;
  final Color bgColor;
  final RxSet<String> selectedVariantIds;
  final void Function(String?) onVariantToggle;
  final double averageDiscount;

  const _StoreCard({
    required this.businessName,
    required this.businessLogo,
    required this.businessAddress,
    required this.items,
    required this.controller,
    required this.bgColor,
    required this.selectedVariantIds,
    required this.onVariantToggle,
    required this.averageDiscount,
  });

  @override
  Widget build(BuildContext context) {
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
            _buildHeader(),
            if (businessAddress.isNotEmpty) _buildAddressRow(),
            ...List.generate(items.length, (i) {
              final v = items[i];
              // Why: productImage is in a SEPARATE map (cartProductImages),
              // not inside cartBusinessInfo. Reading it from the right
              // place is what makes the thumbnail render when the variant
              // itself has no images attached.
              final fallbackImage =
                  controller.cartProductImages[v.sId] ?? '';
              return _ProductRow(
                variant: v,
                fallbackImage: fallbackImage,
                controller: controller,
                isSelected: selectedVariantIds.contains(v.sId),
                onToggle: () => onVariantToggle(v.sId),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String? get _distanceLabel {
    // Compute live distance from the user's current location to the
    // business lat/lng stashed at add-to-cart time. calculateDistance
    // returns null when either side is missing/zero.
    final lat =
        double.tryParse(businessInfo['lat']?.toString() ?? '') ?? 0.0;
    final lng =
        double.tryParse(businessInfo['lng']?.toString() ?? '') ?? 0.0;
    if (lat == 0 && lng == 0) return null;
    final km = calculateDistance(lat, lng);
    if (km == null) return null;
    return '${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} km Away';
  }

  String? get _shopTypeLabel {
    final raw = (businessInfo['shopType'] ??
            businessInfo['categoryName'] ??
            businessInfo['category'] ??
            businessInfo['natureOfBusiness'])
        ?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return raw;
  }

  // The card needs the businessInfo map for distance / shop-type lookup;
  // it lives on the parent Map but we want it accessible in the helpers
  // without threading another constructor arg. Read it lazily off the
  // controller using the first variant's sId as the join key (same way
  // the parent screen does).
  Map get businessInfo {
    final id = items.isNotEmpty ? items.first.sId : null;
    if (id == null) return const {};
    return controller.cartBusinessInfo[id] ?? const {};
  }

  Widget _buildHeader() {
    final distance = _distanceLabel;
    final shopType = _shopTypeLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatarWidget(
            imageUrl: businessLogo,
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
                  businessName,
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
          if (averageDiscount > 0) _DiscountRibbon(percent: averageDiscount),
        ],
      ),
    );
  }

  Widget _buildAddressRow() {
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

/// Single-column vertical dashed line — short segments with a gap
/// between them along the Y-axis, antialiased on a 1-px stroke.
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

/// Mirrors the shop-type pill but tinted neutral so the two chips read
/// as a pair instead of competing for color emphasis. Pin icon + text in
/// the same secondary-text color the row already uses.
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
        border: Border.all(
          color: AppColors.greyE5,
          width: 0.6,
        ),
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
//  PRODUCT ROW
// ═══════════════════════════════════════════════════════════════════

class _ProductRow extends StatelessWidget {
  final ProductVariants variant;
  final String fallbackImage;
  final GrocerySelfPickupConsumerController controller;
  final bool isSelected;
  final VoidCallback onToggle;

  const _ProductRow({
    required this.variant,
    required this.fallbackImage,
    required this.controller,
    required this.isSelected,
    required this.onToggle,
  });

  void _handleRemove(BuildContext context) {
    final qty = controller.getQuantity(variant.sId);
    if (qty > 1) {
      controller.removeFromCart(variant);
      return;
    }
    // qty is about to drop to 0 — confirm with the user before evicting
    // the variant from the cart.
    Get.dialog(
      Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final hasDiscount =
        mrp > sellingPrice && mrp != 0 && sellingPrice != 0;
    final discountPct = hasDiscount
        ? (((mrp - sellingPrice) / mrp) * 100).round()
        : 0;

    // Image source priority: variant.images → fallbackImage (parent
    // product image stored on cartProductImages) → placeholder.
    final variantImage =
        (variant.images != null && variant.images!.isNotEmpty)
            ? (variant.images!.first.url ?? '')
            : '';
    final imageUrl =
        variantImage.isNotEmpty ? variantImage : fallbackImage;

    // Selection paints in three subtle layers — bg wash, border tint,
    // and a soft primary-tinted shadow — instead of one loud accent.
    // Animated together so the row breathes when toggled.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        // Why: alphaBlend onto white so the selection wash stays opaque
        // — a transparent tint would let the pastel store card bleed
        // through and muddy the row's whites.
        color: isSelected
            ? Color.alphaBlend(
                AppColors.primaryColor.withValues(alpha: 0.04),
                AppColors.white,
              )
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.35)
              : AppColors.greyE5,
          width: 0.6,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox — same custom animated mark used elsewhere on
          // the screen (kept the InkWell wrapper so only the 18×18
          // hit zone toggles, matching the original tap behavior).
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.greyCA,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Thumbnail — soft framed box with its own gentle shadow so
          // it reads as a small product tile rather than a flat crop.
          // Fades to 55% opacity when unchecked: a glance tells you
          // which items the order will skip.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.55,
            child: Container(
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
          ),
          const SizedBox(width: 12),
          // Title + meta. Two clean tiers: variant name (bumped to
          // weight 700 for presence), then a "qty · ₹X/unit" caption
          // separated by a typographic middle dot — replaces the
          // 0.6×10 pixel divider, which read as a stray artifact at
          // small sizes.
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
          // Vertical dashed divider — kept as the screen's signature
          // aesthetic. Slightly taller (60) so it spans the
          // price → discount → stepper trio cleanly when a discount
          // chip is present.
          const _VerticalDashedLine(height: 60),
          const SizedBox(width: 10),
          // Right column: selling price (dominant), strikethrough MRP
          // + lime "% off" chip below it (only when discounted), and
          // the qty stepper at the bottom. The chip uses the same
          // green family as the store card's discount ribbon so the
          // savings story stays color-consistent across the screen.
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
              // Why: Obx so the quantity number repaints when add/remove
              // mutates controller.cartQuantities — without this the
              // stepper text stays frozen at the build-time value.
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
    // Sized for in-row presence: 34×34 tap targets and 16-px icons
    // with a weight-800 qty number. Light primary wash — no border,
    // no shadow — so the stepper sits inside the row as a tinted
    // control rather than a floating elevated box. The +/- glyphs
    // render in primaryColor; the minus glyph flips to a red delete
    // icon at qty 1 so the destructive transition is telegraphed
    // before the confirm dialog opens.
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
                  color: quantity == 1
                      ? AppColors.red
                      : AppColors.primaryColor,
                  size: 16,
                ),
              ),
            ),
          ),
          // Number lane — minWidth 22 so the stepper doesn't shimmy
          // horizontally when the qty crosses 9 → 10 (single → double
          // digit). Centered glyph keeps the layout symmetric.
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
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
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
    return isWhole
        ? clamped.toStringAsFixed(0)
        : clamped.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Why: radial gradient (lime center → deep-green edge) gives
          // the badge the "stamped" feel from the mockup, and the 2px
          // yellow ring frames it like a sticker on the card corner.
          gradient: const RadialGradient(
            center: Alignment(-0.2, -0.4),
            radius: 1.1,
            // Why: prior #EEFB7E center read too acidic; #B5D147 is the
            // same lime family but a touch darker so the white text /
            // yellow border don't fight it for contrast.
            colors: [Color(0xFFB5D147), Color(0xFF0D8A47)],
            stops: [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFFD83D),
            width: 2,
          ),
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
            // "20% Off" laid out as a single row so the % and word read
            // together — matches the mockup's hierarchy.
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
//  BOTTOM SUMMARY BAR (per-shop checkboxes + grand total + Place Order)
// ═══════════════════════════════════════════════════════════════════

class _BottomSummaryBar extends StatelessWidget {
  final Map<String, List<ProductVariants>> grouped;
  final GrocerySelfPickupConsumerController controller;
  final double Function(List<ProductVariants>,
      GrocerySelfPickupConsumerController) calcTotal;
  final int Function(List<ProductVariants>,
      GrocerySelfPickupConsumerController) calcItemCount;
  final RxSet<String> selectedBusinessIds;
  final VoidCallback onPlaceOrder;

  const _BottomSummaryBar({
    required this.grouped,
    required this.controller,
    required this.calcTotal,
    required this.calcItemCount,
    required this.selectedBusinessIds,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Force subscription to qty changes — calcTotal reads cartQuantities
      // indirectly via getQuantity, but touching the map's length here
      // guarantees this Obx rebuilds on every +/− tap.
      // ignore: unused_local_variable
      final _ = controller.cartQuantities.length;
      double grandTotal = 0;
      int grandItemCount = 0;
      int selectedShopCount = 0;

      for (var entry in grouped.entries) {
        if (selectedBusinessIds.contains(entry.key)) {
          grandTotal += calcTotal(entry.value, controller);
          grandItemCount += calcItemCount(entry.value, controller);
          selectedShopCount++;
        }
      }

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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...grouped.entries.map((entry) {
                  final businessId = entry.key;
                  final items = entry.value;
                  final businessInfo =
                      controller.cartBusinessInfo[items.first.sId] ?? {};
                  final shopName = businessInfo['businessName'] ??
                      AppStrings.groceryViewUnknownStore.tr;
                  final shopTotal = calcTotal(items, controller);
                  final shopItems = calcItemCount(items, controller);
                  final isChecked =
                      selectedBusinessIds.contains(businessId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () {
                        if (isChecked) {
                          selectedBusinessIds.remove(businessId);
                        } else {
                          selectedBusinessIds.add(businessId);
                        }
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isChecked,
                              onChanged: (val) {
                                if (val == true) {
                                  selectedBusinessIds.add(businessId);
                                } else {
                                  selectedBusinessIds.remove(businessId);
                                }
                              },
                              activeColor: AppColors.primaryColor,
                              checkColor: AppColors.white,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomText(
                              '$shopName ($shopItems ${shopItems == 1 ? AppStrings.groceryViewItemLabel.tr : AppStrings.groceryViewItemsLabel.tr})',
                              fontSize: SizeConfig.small,
                              color: isChecked
                                  ? AppColors.primaryColor
                                  : AppColors.greyCA,
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CustomText(
                            '₹${shopTotal.toStringAsFixed(2)}',
                            fontSize: SizeConfig.small,
                            color: isChecked
                                ? AppColors.mainTextColor
                                : AppColors.greyCA,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(height: 16, color: AppColors.greyE5),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            '$selectedShopCount ${selectedShopCount == 1 ? AppStrings.groceryViewShopLabel.tr : AppStrings.groceryViewShopsLabel.tr} | $grandItemCount ${grandItemCount == 1 ? AppStrings.groceryViewProductLabel.tr : AppStrings.groceryViewProductsLabel.tr}',
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            '₹${grandTotal.toStringAsFixed(2)}',
                            fontSize: SizeConfig.extraLarge,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      // Why: gate on grandItemCount (counts only variants
                      // whose shop AND variant checkbox are both on),
                      // not selectedShopCount. So a single-shop cart with
                      // every product unchecked correctly disables the
                      // button, while multi-shop carts stay actionable
                      // as long as ANY shop still has checked items.
                      child: Builder(builder: (_) {
                        final canOrder = grandItemCount > 0;
                        return InkWell(
                          onTap: canOrder ? onPlaceOrder : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: canOrder
                                  ? AppColors.primaryColor
                                  : AppColors.greyCA,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: canOrder
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: CustomText(
                              AppStrings.groceryViewPlaceOrder.tr,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
