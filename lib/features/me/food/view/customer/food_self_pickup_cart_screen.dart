import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Self-pickup cart for the food flow. Mirrors the grocery cart screen
/// (`GrocerySelfPickUpCartScreen`) — items are grouped by store, each
/// product row carries a per-variant checkbox and qty stepper, and the
/// bottom summary bar exposes per-shop checkboxes + a grand total +
/// Place Order button. Submitting fires a bulk food order on
/// [FoodSelfPickupController] which then hops the user to the chat
/// Orders tab.
class FoodSelfPickUpCartScreen extends StatefulWidget {
  const FoodSelfPickUpCartScreen({super.key});

  @override
  State<FoodSelfPickUpCartScreen> createState() =>
      _FoodSelfPickUpCartScreenState();
}

class _FoodSelfPickUpCartScreenState extends State<FoodSelfPickUpCartScreen> {
  // Card backgrounds rotated by store index so the multi-shop list
  // reads as discrete cards. Same palette idea as grocery, swapped to
  // warmer hues to suit the food context.
  static const List<Color> _cardColors = [
    Color(0xFFFFFEF7),
    Color(0xFFFFF9F3),
    Color(0xFFFFF5F5),
  ];

  /// Stores the user has opted-into for the order.
  final RxSet<String> selectedBusinessIds = <String>{}.obs;

  /// Variants the user wants in the order — defaulted to "all" on first
  /// build; the user can deselect individual rows from the store card.
  final RxSet<String> selectedVariantIds = <String>{}.obs;

  bool _initialized = false;

  Map<String, List<FoodVariants>> _groupByBusiness(
      FoodSelfPickupController controller) {
    final Map<String, List<FoodVariants>> grouped = {};
    for (var variant in controller.selectedFoodVariants) {
      final info = controller.cartBusinessInfo[variant.id];
      final businessId = info?['businessId'] ?? 'unknown';
      grouped.putIfAbsent(businessId, () => []).add(variant);
    }
    if (!_initialized && grouped.isNotEmpty) {
      selectedBusinessIds.addAll(grouped.keys);
      for (final v in controller.selectedFoodVariants) {
        final id = v.id;
        if (id != null) selectedVariantIds.add(id);
      }
      _initialized = true;
    }
    return grouped;
  }

  double _calcTotal(
      List<FoodVariants> items, FoodSelfPickupController controller) {
    double total = 0;
    for (var v in items) {
      if (!selectedVariantIds.contains(v.id)) continue;
      final qty = controller.getQuantity(v.id);
      final sp = (v.baseSellingPrice ?? 0).toDouble();
      total += sp * qty;
    }
    return total;
  }

  int _calcItemCount(
      List<FoodVariants> items, FoodSelfPickupController controller) {
    int count = 0;
    for (var v in items) {
      if (!selectedVariantIds.contains(v.id)) continue;
      count += controller.getQuantity(v.id);
    }
    return count;
  }

  /// Average discount % across the store's variants — used by the
  /// corner ribbon. Variants with no MRP / no selling price are skipped.
  double _calcAverageDiscount(List<FoodVariants> items) {
    double total = 0;
    int count = 0;
    for (var v in items) {
      final mrp = (v.mrp ?? 0).toDouble();
      final sp = (v.baseSellingPrice ?? 0).toDouble();
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
  /// from the controller's cart, then place the order. Without this,
  /// the API would receive every variant in the cart regardless of
  /// checkbox state. Same approach as the grocery cart.
  void _placeOrder(FoodSelfPickupController controller,
      Map<String, List<FoodVariants>> grouped) {
    final toDrop = <FoodVariants>[];
    for (final entry in grouped.entries) {
      final shopChecked = selectedBusinessIds.contains(entry.key);
      for (final v in entry.value) {
        final variantChecked = selectedVariantIds.contains(v.id);
        if (!shopChecked || !variantChecked) toDrop.add(v);
      }
    }

    // removeFromCart decrements by 1 per call; loop until qty hits 0
    // so the variant is fully evicted before the order goes out.
    for (final v in toDrop) {
      while (controller.getQuantity(v.id) > 0) {
        controller.removeFromCart(v);
      }
    }

    controller.placeFoodOrderApi();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FoodSelfPickupController>();

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
          AppStrings.foodSelfPickupLabel.tr,
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
        final variants = controller.selectedFoodVariants;

        if (variants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 64, color: AppColors.greyCA),
                const SizedBox(height: 16),
                CustomText(
                  AppStrings.foodNoItemsInPickup.tr,
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
                      controller.cartBusinessInfo[items.first.id] ?? {};
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
  final List<FoodVariants> items;
  final FoodSelfPickupController controller;
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
              // Food variants don't carry their own image list. The
              // controller stashes the parent product's image at
              // add-to-cart time in `cartProductImages` keyed by
              // variant id, so use that as the thumbnail source.
              final fallbackImage = controller.cartProductImages[v.id] ?? '';
              return _ProductRow(
                variant: v,
                fallbackImage: fallbackImage,
                controller: controller,
                isSelected: selectedVariantIds.contains(v.id),
                onToggle: () => onVariantToggle(v.id),
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
    // business lat/lng stashed at add-to-cart time. Returns null if
    // either side is missing/zero (cartBusinessInfo on food may not
    // carry coords yet, in which case the pill simply hides).
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
  // controller using the first variant's id as the join key (same way
  // the parent screen does).
  Map get businessInfo {
    final id = items.isNotEmpty ? items.first.id : null;
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
/// as a pair instead of competing for color emphasis. Pin icon + text
/// in the same secondary-text color the row already uses.
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
  final FoodVariants variant;
  final String fallbackImage;
  final FoodSelfPickupController controller;
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
    final qty = controller.getQuantity(variant.id);
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
    final sellingPrice = variant.baseSellingPrice ?? 0;
    final mrp = variant.mrp ?? 0;
    // Food variants have no per-variant image list, so the only
    // source is the parent-product image stashed on cartProductImages.
    final imageUrl = fallbackImage;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.25)
              : AppColors.greyE5,
          width: 0.6,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
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
          const SizedBox(width: 8),
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: SizeConfig.size50,
              height: SizeConfig.size50,
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
          const SizedBox(width: 10),
          // Title + unit-price line
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  variant.variantName ?? '',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CustomText(
                      '${variant.quantityLabel ?? ''}',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    if ((variant.quantityLabel ?? '').isNotEmpty &&
                        sellingPrice != 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 0.6,
                        height: 10,
                        color: AppColors.greyCA,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (sellingPrice != 0)
                      Flexible(
                        child: CustomText(
                          // Food has no `unit` field on the variant —
                          // omit it from the unit-price line instead
                          // of leaving a trailing slash.
                          '${AppConstants.rupeeSymbol}$sellingPrice',
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
          const SizedBox(width: 8),
          // Vertical dashed divider — separates product details (left)
          // from the price + qty controls (right). Custom-painted so
          // the dashes run cleanly down a 1-px column.
          const _VerticalDashedLine(height: 56),
          const SizedBox(width: 8),
          // Right column: price + qty stepper
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    '${AppConstants.rupeeSymbol}$sellingPrice',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  if (mrp > sellingPrice && mrp != 0) ...[
                    const SizedBox(width: 4),
                    CustomText(
                      '${AppConstants.rupeeSymbol}$mrp',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.secondaryTextColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // Why: Obx so the quantity number repaints when add/remove
              // mutates controller.cartQuantities — without this the
              // stepper text stays frozen at the build-time value.
              Obx(() => _QtyStepper(
                    quantity: controller.getQuantity(variant.id),
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
    // before the confirm dialog opens. Same control vocabulary as
    // the grocery + product carts.
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
          // Number lane — minWidth 22 keeps the stepper from
          // shimmying when qty crosses 9 → 10 (single → double digit).
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
          // the badge the "stamped" feel from the grocery mockup, and
          // the 2-px yellow ring frames it like a sticker on the card
          // corner.
          gradient: const RadialGradient(
            center: Alignment(-0.2, -0.4),
            radius: 1.1,
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
            // "20% Off" laid out as a single row so the % and word
            // read together — matches the grocery hierarchy.
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
  final Map<String, List<FoodVariants>> grouped;
  final FoodSelfPickupController controller;
  final double Function(List<FoodVariants>, FoodSelfPickupController) calcTotal;
  final int Function(List<FoodVariants>, FoodSelfPickupController)
      calcItemCount;
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
      // Force subscription to qty changes — calcTotal reads
      // cartQuantities indirectly via getQuantity, but touching the
      // map's length here guarantees this Obx rebuilds on every +/− tap.
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
                      controller.cartBusinessInfo[items.first.id] ?? {};
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
                              '$shopName ($shopItems ${shopItems == 1 ? AppStrings.foodItemSingular.tr : AppStrings.foodItemPlural.tr})',
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
                            '${AppConstants.rupeeSymbol}${shopTotal.toStringAsFixed(2)}',
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
                            '$selectedShopCount ${selectedShopCount == 1 ? AppStrings.foodShopSingular.tr : AppStrings.foodShopPlural.tr} | $grandItemCount ${grandItemCount == 1 ? AppStrings.foodProductSingular.tr : AppStrings.foodProductPlural.tr}',
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            '${AppConstants.rupeeSymbol}${grandTotal.toStringAsFixed(2)}',
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
                      // not selectedShopCount. So a single-shop cart
                      // with every product unchecked correctly disables
                      // the button, while multi-shop carts stay
                      // actionable as long as ANY shop still has
                      // checked items.
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
                              AppStrings.foodPlaceOrderLabel.tr,
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
