import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/discount_ribbon.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/order_checkout_stepper_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Self-pickup cart for the product flow. Mirrors the grocery cart —
/// pastel store cards, framed thumbnails, vertical dashed dividers,
/// per-product + per-shop checkbox selection, lime "% off" chips, and
/// a sheet-like bottom bar with per-shop totals + grand total + flat
/// Place Order CTA.
class ManufacturerProductSelfPickUpCartScreen extends StatefulWidget {
  const ManufacturerProductSelfPickUpCartScreen({super.key});

  @override
  State<ManufacturerProductSelfPickUpCartScreen> createState() =>
      _ProductSelfPickUpCartScreenState();
}

class _ProductSelfPickUpCartScreenState
    extends State<ManufacturerProductSelfPickUpCartScreen> {
  // Card backgrounds rotated by store index so the multi-shop list
  // reads as discrete, distinguishable surfaces.
  static const List<Color> _cardColors = [
    Color(0xFFEFF6FF),
    Color(0xFFF6F0FF),
    Color(0xFFFFF5EC),
  ];

  /// Stores the user has opted-into for the order.
  final RxSet<String> selectedBusinessIds = <String>{}.obs;

  /// Variants the user wants in the order — defaulted to "all" on
  /// first build, then user can deselect individual rows from the
  /// store card.
  final RxSet<String> selectedVariantIds = <String>{}.obs;

  bool _initialized = false;

  String? _variantIdOf(GetProductData product) {
    final variants = product.product.sellerClassification?.variants;
    if (variants == null || variants.isEmpty) return null;
    final id = variants.first.id;
    return id.isEmpty ? null : id;
  }

  Map<String, List<GetProductData>> _groupByBusiness(
      ManufacturerProductSelfPickupController controller) {
    final Map<String, List<GetProductData>> grouped = {};
    for (final p in controller.selectedProductVariants) {
      final id = _variantIdOf(p);
      final info = id == null ? null : controller.cartBusinessInfo[id];
      final bId = info?['businessId'] ?? 'unknown';
      grouped.putIfAbsent(bId, () => []).add(p);
    }
    if (!_initialized && grouped.isNotEmpty) {
      selectedBusinessIds.addAll(grouped.keys);
      for (final p in controller.selectedProductVariants) {
        final id = _variantIdOf(p);
        if (id != null) selectedVariantIds.add(id);
      }
      _initialized = true;
    }
    return grouped;
  }

  double _calcTotal(List<GetProductData> items,
      ManufacturerProductSelfPickupController controller) {
    double total = 0;
    for (final p in items) {
      final id = _variantIdOf(p);
      if (id == null || !selectedVariantIds.contains(id)) continue;
      final qty = controller.getQuantity(id);
      final variants = p.product.sellerClassification?.variants ?? [];
      final sp = variants.isNotEmpty ? (variants.first.sellingPrice) : 0;
      total += sp * qty;
    }
    return total;
  }

  int _calcItemCount(List<GetProductData> items,
      ManufacturerProductSelfPickupController controller) {
    int count = 0;
    for (final p in items) {
      final id = _variantIdOf(p);
      if (id == null || !selectedVariantIds.contains(id)) continue;
      count += controller.getQuantity(id);
    }
    return count;
  }

  /// Average discount % across the store's variants — used by the
  /// corner ribbon. Variants with no MRP / no selling price are
  /// skipped so a single bad row can't pull the average to zero.
  double _calcAverageDiscount(List<GetProductData> items) {
    double total = 0;
    int count = 0;
    for (var p in items) {
      final variants = p.product.sellerClassification?.variants ?? [];
      if (variants.isEmpty) continue;
      final mrp = (variants.first.mrp).toDouble();
      final sp = (variants.first.sellingPrice).toDouble();
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

  /// Strip products the user has unchecked (per-product OR whole-shop)
  /// from the controller's cart, then place the order. Without this
  /// the API would receive every variant in the cart regardless of
  /// checkbox state. Same approach as the grocery cart.

  /// What the checkout sheet shows as the items total: only the shops and
  /// variants still ticked, priced the same way the cart footer prices them.
  double _checkoutTotal(ManufacturerProductSelfPickupController controller,
      Map<String, List<GetProductData>> grouped) {
    return grouped.entries
        .where((e) => selectedBusinessIds.contains(e.key))
        .fold<double>(0, (sum, e) => sum + _calcTotal(e.value, controller));
  }

  Future<void> _placeOrder(ManufacturerProductSelfPickupController controller,
      Map<String, List<GetProductData>> grouped) async {
    final toDrop = <GetProductData>[];
    for (final entry in grouped.entries) {
      final shopChecked = selectedBusinessIds.contains(entry.key);
      for (final p in entry.value) {
        final id = _variantIdOf(p);
        final variantChecked = id != null && selectedVariantIds.contains(id);
        if (!shopChecked || !variantChecked) toDrop.add(p);
      }
    }

    // removeFromCart decrements by 1 per call; loop until qty hits 0
    // so the variant is fully evicted before the order goes out.
    for (final p in toDrop) {
      final id = _variantIdOf(p);
      while (controller.getQuantity(id) > 0) {
        controller.removeFromCart(p);
      }
    }

    // Ask how they'll pay before the order exists. This vertical's service
    // does not take doorstep orders yet, so the sheet skips the delivery steps
    // entirely (`allowDelivery: false`) and asks only what it can honour.
    if (!mounted) return;
    final choice = await showOrderCheckoutSheet(
      context,
      itemsTotal: _checkoutTotal(controller, grouped),
      allowDelivery: false,
    );
    if (choice == null) return;
    controller.paymentMethod.value = choice.paymentMethod;

    controller.placeProductOrderApi();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManufacturerProductSelfPickupController>();

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

        final grouped = _groupByBusiness(controller);
        final businessIds = grouped.keys.toList();

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(SizeConfig.paddingM),
                itemCount: businessIds.length,
                itemBuilder: (context, index) {
                  final bId = businessIds[index];
                  final groupItems = grouped[bId]!;
                  final firstId = _variantIdOf(groupItems.first);
                  final businessInfo = firstId == null
                      ? <String, dynamic>{}
                      : (controller.cartBusinessInfo[firstId] ?? {});

                  return _StoreGroupCard(
                    businessName:
                        businessInfo['businessName'] ?? 'Unknown Store',
                    businessLogo: businessInfo['logo'] ?? '',
                    businessAddress: businessInfo['address'] ?? '',
                    items: groupItems,
                    controller: controller,
                    variantIdOf: _variantIdOf,
                    bgColor: _cardColors[index % _cardColors.length],
                    averageDiscount: _calcAverageDiscount(groupItems),
                    selectedVariantIds: selectedVariantIds,
                    onVariantToggle: _toggleVariant,
                  );
                },
              ),
            ),
            _BottomBillSection(
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
//  STORE GROUP CARD — header + address + inline product list
// ═══════════════════════════════════════════════════════════════════

class _StoreGroupCard extends StatelessWidget {
  final String businessName;
  final String businessLogo;
  final String businessAddress;
  final List<GetProductData> items;
  final ManufacturerProductSelfPickupController controller;
  final String? Function(GetProductData) variantIdOf;
  final Color bgColor;
  final double averageDiscount;
  final RxSet<String> selectedVariantIds;
  final void Function(String?) onVariantToggle;

  const _StoreGroupCard({
    required this.businessName,
    required this.businessLogo,
    required this.businessAddress,
    required this.items,
    required this.controller,
    required this.variantIdOf,
    required this.bgColor,
    required this.averageDiscount,
    required this.selectedVariantIds,
    required this.onVariantToggle,
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
              final p = items[i];
              // Why: wrap each row in its own Obx so flipping the
              // checkbox refreshes only that row's selected visual
              // (bg wash, border, thumbnail opacity). Without this
              // the row stays stale because the parent body Obx only
              // tracks the cart list, not selectedVariantIds.
              return Obx(() {
                final id = variantIdOf(p);
                return _ProductRow(
                  product: p,
                  controller: controller,
                  variantIdOf: variantIdOf,
                  isSelected: id != null && selectedVariantIds.contains(id),
                  onToggle: () => onVariantToggle(id),
                );
              });
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                SizedBox(height: SizeConfig.size4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: CustomText(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (averageDiscount > 0)
            DiscountRibbon(
                percent: averageDiscount,
                padding: const EdgeInsets.only(right: 10)),
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
/// between them along the Y-axis. Screen signature carried over from
/// the grocery cart.
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

// ═══════════════════════════════════════════════════════════════════
//  PRODUCT ROW
// ═══════════════════════════════════════════════════════════════════

class _ProductRow extends StatelessWidget {
  final GetProductData product;
  final ManufacturerProductSelfPickupController controller;
  final String? Function(GetProductData) variantIdOf;
  final bool isSelected;
  final VoidCallback onToggle;

  const _ProductRow({
    required this.product,
    required this.controller,
    required this.variantIdOf,
    required this.isSelected,
    required this.onToggle,
  });

  void _handleRemove(BuildContext context) {
    final id = variantIdOf(product);
    final qty = controller.getQuantity(id);
    if (qty > 1) {
      controller.removeFromCart(product);
      return;
    }
    // qty is about to drop to 0 — confirm with the user before
    // evicting the item from the cart. Mirrors the grocery cart's
    // confirm flow so destructive actions look consistent.
    final productName = product.product.details?.name ?? 'This product';
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
                '"$productName" will be removed from your cart.',
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
                        controller.removeFromCart(product);
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
    final details = product.product.details;
    final variants = product.product.sellerClassification?.variants ?? [];
    final firstVariant = variants.isNotEmpty ? variants.first : null;
    final img =
        (details?.media.isNotEmpty ?? false) ? details!.media.first : '';
    final sellingPrice = firstVariant?.sellingPrice ?? 0;
    final mrp = firstVariant?.mrp ?? 0;
    final id = variantIdOf(product);
    final hasDiscount = mrp > sellingPrice && mrp != 0 && sellingPrice != 0;
    final discountPct =
        hasDiscount ? (((mrp - sellingPrice) / mrp) * 100).round() : 0;

    // Selection paints in three subtle layers — bg wash, border tint,
    // and a soft primary shadow — animated together so the row
    // breathes when toggled.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        // alphaBlend onto white keeps the wash opaque so the pastel
        // store card doesn't bleed through and muddy the row.
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
          // Animated checkbox — same custom mark used elsewhere on
          // the screen (kept the InkWell wrapper so only the 18×18
          // hit zone toggles, matching grocery's tap behavior).
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
                  color:
                      isSelected ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primaryColor : AppColors.greyCA,
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
          // Thumbnail — soft framed box with its own gentle shadow.
          // Fades to 55 % opacity when unchecked: a glance tells you
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
                  child: img.isEmpty
                      ? LocalAssets(
                          imagePath: AppIconAssets.place_holder_image,
                          boxFix: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: img,
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
          // Title + unit-price caption.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  details?.name ?? '',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sellingPrice != 0) ...[
                  const SizedBox(height: 5),
                  CustomText(
                    '${AppConstants.rupeeSymbol}$sellingPrice each',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
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
                '${AppConstants.rupeeSymbol}$sellingPrice',
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
                      '${AppConstants.rupeeSymbol}$mrp',
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
                    quantity: controller.getQuantity(id),
                    onAdd: () => controller.addToCart(product),
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
    // 34×34 tap targets, 16-px primary +/- icons, weight-800 qty
    // number. Light primary wash — no border, no shadow — so the
    // stepper sits inside the row as a tinted control rather than a
    // floating elevated box.
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
                  color: quantity == 1 ? AppColors.red : AppColors.primaryColor,
                  size: 16,
                ),
              ),
            ),
          ),
          // Number lane — minWidth 22 keeps the stepper from
          // shimmying when qty crosses 9 → 10.
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
//  BOTTOM BILL SECTION (per-shop checkboxes + grand total + CTA)
// ═══════════════════════════════════════════════════════════════════

class _BottomBillSection extends StatelessWidget {
  final Map<String, List<GetProductData>> grouped;
  final ManufacturerProductSelfPickupController controller;
  final double Function(
      List<GetProductData>, ManufacturerProductSelfPickupController) calcTotal;
  final int Function(
          List<GetProductData>, ManufacturerProductSelfPickupController)
      calcItemCount;
  final RxSet<String> selectedBusinessIds;
  final VoidCallback onPlaceOrder;

  const _BottomBillSection({
    required this.grouped,
    required this.controller,
    required this.calcTotal,
    required this.calcItemCount,
    required this.selectedBusinessIds,
    required this.onPlaceOrder,
  });

  String? _firstIdOf(List<GetProductData> items) {
    if (items.isEmpty) return null;
    final variants = items.first.product.sellerClassification?.variants ?? [];
    if (variants.isEmpty) return null;
    final id = variants.first.id;
    return id.isEmpty ? null : id;
  }

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  final firstId = _firstIdOf(items);
                  final businessInfo = firstId == null
                      ? <String, dynamic>{}
                      : (controller.cartBusinessInfo[firstId] ?? {});
                  final shopName =
                      businessInfo['businessName'] ?? 'Unknown Store';
                  final shopTotal = calcTotal(items, controller);
                  final shopItems = calcItemCount(items, controller);
                  final isChecked = selectedBusinessIds.contains(businessId);

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
                              '$shopName ($shopItems ${shopItems == 1 ? 'item' : 'items'})',
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
                            '$selectedShopCount ${selectedShopCount == 1 ? 'Shop' : 'Shops'} | $grandItemCount ${grandItemCount == 1 ? 'ManufacturerProduct' : 'Products'}',
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
                    // Why: gate on grandItemCount (counts only variants
                    // whose shop AND variant checkbox are both on),
                    // not selectedShopCount. So a single-shop cart with
                    // every product unchecked correctly disables the
                    // button, while multi-shop carts stay actionable
                    // as long as ANY shop still has checked items.
                    Expanded(
                      child: Builder(builder: (_) {
                        final loading =
                            controller.isPlaceProductOrderLoading.value;
                        final canOrder = grandItemCount > 0 && !loading;
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
                            child: loading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.white),
                                    ),
                                  )
                                : CustomText(
                                    'Place Order',
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
