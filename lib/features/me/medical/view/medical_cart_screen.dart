import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/discount_ribbon.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pharmacy cart — one pharmacy card holding the item rows, then a place-order
/// bar. Structurally identical to [GrocerySelfPickUpCartScreen] (tinted store
/// card, header pills, discount ribbon, dashed-divider product rows, `- N +`
/// steppers, place-order bar), with one difference: it shows ONE card rather
/// than a list, because the pharmacy cart is single-store.
///
/// Orders here are always **self-pickup** — [MedicalCartController.deliveryType]
/// keeps its default and nothing on this screen changes it, matching grocery,
/// which hardcodes the same. Rider delivery runs through its own flow
/// (`user_medical_controller`), not this cart.
class MedicalCartScreen extends StatelessWidget {
  const MedicalCartScreen({super.key});

  static const Color _primary = AppColors.primaryColor;
  static const Color _primaryDeep = AppColors.blue5CAF;

  /// First of grocery's rotating card tints — only one card here, so the
  /// rotation has nothing to rotate through.
  static const Color _cardColor = Color(0xFFEFF6FF);

  @override
  Widget build(BuildContext context) {
    final cart = getOrPut(() => MedicalCartController(), permanent: true);

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
        title: CustomText(
          'Your Cart',
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
        // Subscribe to add/remove/qty changes so the card + totals repaint.
        // ignore: unused_local_variable
        final _ = cart.cartQuantities.length;
        // ignore: unused_local_variable
        final __ = cart.cartLines.length;

        if (cart.isEmpty) return _emptyState();

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(SizeConfig.paddingM),
                children: [
                  _PharmacyCard(cart: cart, bgColor: _cardColor),
                ],
              ),
            ),
            _PlaceOrderBar(cart: cart),
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
            'Your cart is empty',
            fontSize: SizeConfig.large,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  /// Shared gradient primary checkout button.
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
//  PHARMACY CARD — header + item rows
// ═══════════════════════════════════════════════════════════════════

class _PharmacyCard extends StatelessWidget {
  final MedicalCartController cart;
  final Color bgColor;

  const _PharmacyCard({required this.cart, required this.bgColor});

  MedicalCartBusiness? get _business => cart.business.value;

  List<MedicalCartLine> get _lines => cart.cartLines.values.toList();

  /// Mean discount across the cart's lines — drives the ribbon. Lines with no
  /// MRP (or an MRP at/below the selling price) contribute nothing.
  double _calcAverageDiscount(List<MedicalCartLine> lines) {
    double total = 0;
    int count = 0;
    for (final l in lines) {
      final mrp = l.mrpValue;
      final sp = l.sellingValue;
      if (mrp <= 0 || sp <= 0 || sp >= mrp) continue;
      total += ((mrp - sp) / mrp) * 100;
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  String? get _distanceLabel {
    final lat = _business?.lat ?? 0.0;
    final lng = _business?.lng ?? 0.0;
    if (lat == 0 && lng == 0) return null;
    final km = calculateDistance(lat, lng);
    if (km == null) return null;
    return '${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} km Away';
  }

  String? get _shopTypeLabel {
    final raw = _business?.category;
    if (raw == null || raw.trim().isEmpty) return null;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    final name = (_business?.businessName ?? '').isNotEmpty
        ? _business!.businessName
        : 'Pharmacy';
    final logo = _business?.logo ?? '';
    final address = _business?.address ?? '';
    final averageDiscount = _calcAverageDiscount(lines);

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
            _buildHeader(context, name, logo, averageDiscount),
            if (address.isNotEmpty) _buildAddressRow(address),
            ...lines.map((l) => _ItemRow(line: l, cart: cart)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String name, String logo, double avgDiscount) {
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
          if (avgDiscount > 0) DiscountRibbon(percent: avgDiscount),
          // Clear the whole cart — single-store, so this empties it.
          InkWell(
            onTap: () => _confirmClear(context),
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

  /// The cart is single-store, so clearing the pharmacy empties everything —
  /// confirm first rather than wiping the cart on a stray tap.
  void _confirmClear(BuildContext context) {
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
                    child: CustomText('Clear cart?',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomText(
                'Every item from this pharmacy will be removed.',
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
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: CustomText('Cancel',
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        cart.clearAll();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: CustomText('Clear',
                          color: AppColors.white,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w800),
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

  Widget _buildAddressRow(String address) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 12, color: AppColors.secondaryTextColor),
          const SizedBox(width: 3),
          Expanded(
            child: CustomText(
              address,
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

// ═══════════════════════════════════════════════════════════════════
//  ITEM ROW
// ═══════════════════════════════════════════════════════════════════

class _ItemRow extends StatelessWidget {
  final MedicalCartLine line;
  final MedicalCartController cart;

  const _ItemRow({required this.line, required this.cart});

  /// `-` at qty 1 removes the line, so confirm before dropping it.
  void _handleRemove(BuildContext context) {
    if (cart.getQuantity(line.variantId) > 1) {
      cart.removeOne(line.variantId);
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
                    child: CustomText('Remove from cart?',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomText(
                '"${line.productName ?? 'This item'}" will be removed from your cart.',
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
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: CustomText('Cancel',
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        cart.removeLine(line.variantId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: CustomText('Remove',
                          color: AppColors.white,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w800),
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

  /// "brand · form" — the variant name is the row title, so it's not repeated.
  String get _subtitle {
    final parts = <String>[];
    if ((line.brand ?? '').isNotEmpty) parts.add(line.brand!);
    if ((line.productForm ?? '').isNotEmpty) parts.add(line.productForm!);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final selling = line.sellingValue;
    final mrp = line.mrpValue;
    final hasDiscount = mrp > selling && mrp > 0 && selling > 0;
    final discountPct =
        hasDiscount ? (((mrp - selling) / mrp) * 100).round() : 0;
    final imageUrl = line.imageUrl ?? '';
    final subtitle = _subtitle;

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
                        // contain — medicine packs are product shots on white.
                        fit: BoxFit.contain,
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
                Row(
                  children: [
                    if (line.isPrescriptionRequired) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: AppColors.red, width: 0.5),
                        ),
                        child: CustomText('Rx',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: CustomText(
                        line.productName ?? line.variantName ?? '',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if ((line.variantName ?? '').isNotEmpty)
                      Flexible(
                        child: CustomText(
                          line.variantName!,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if ((line.variantName ?? '').isNotEmpty &&
                        subtitle.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      CustomText('·',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.greyCA),
                      const SizedBox(width: 6),
                    ],
                    if (subtitle.isNotEmpty)
                      Flexible(
                        child: CustomText(
                          subtitle,
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
                '${AppConstants.rupeeSymbol}${selling.toStringAsFixed(0)}',
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
                      '${AppConstants.rupeeSymbol}${mrp.toStringAsFixed(0)}',
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
                    quantity: cart.getQuantity(line.variantId),
                    onAdd: () => cart.addLine(line),
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
                  color: quantity == 1 ? AppColors.red : AppColors.primaryColor,
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
//  PILLS + DISCOUNT RIBBON
// ═══════════════════════════════════════════════════════════════════

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

/// Single-column vertical dashed line separating an item's detail from its
/// price/stepper column.
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
//  PLACE ORDER BAR
// ═══════════════════════════════════════════════════════════════════

class _PlaceOrderBar extends StatelessWidget {
  final MedicalCartController cart;
  const _PlaceOrderBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ignore: unused_local_variable
      final _ = cart.cartQuantities.length; // subscribe
      final total = cart.totalSellingPrice;
      final items = cart.totalItemsCount;
      final placing = cart.isPlacingOrder.value;
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
                        '$items ${items == 1 ? 'item' : 'items'}',
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
                  child: MedicalCartScreen.checkoutButton(
                    label: AppStrings.placeOrder.tr,
                    // Guard the in-flight request — `placeOrder` has no
                    // re-entrancy check of its own, so a double tap would post
                    // the order twice.
                    onTap: placing ? () {} : cart.placeOrder,
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
