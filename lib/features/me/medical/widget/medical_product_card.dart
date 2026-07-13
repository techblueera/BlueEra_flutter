import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Flat product view used by [MedicalProductCard]. Constructed at the call
/// site from either `PopularProduct` or `CategoryProduct` — the card itself
/// is agnostic to the source API shape.
class MedicalCardProduct {
  final String? productId;
  final String? name;
  final String? brand;
  final String? form;
  final bool isPrescriptionRequired;
  final String? imageUrl;
  final List<MedicalCardVariant> variants;

  const MedicalCardProduct({
    this.productId,
    this.name,
    this.brand,
    this.form,
    this.isPrescriptionRequired = false,
    this.imageUrl,
    this.variants = const [],
  });
}

class MedicalCardVariant {
  final String variantId;
  final String? variantName;
  final String? inventoryId;
  final num? mrp;
  final num? sellingPrice;
  final String? imageUrl;

  const MedicalCardVariant({
    required this.variantId,
    this.variantName,
    this.inventoryId,
    this.mrp,
    this.sellingPrice,
    this.imageUrl,
  });

  int get discountPct {
    final m = (mrp ?? 0).toDouble();
    final s = (sellingPrice ?? 0).toDouble();
    if (m <= 0 || s <= 0 || s >= m) return 0;
    return (((m - s) / m) * 100).round();
  }
}

/// Compact pharmacy product card. Mirrors the grocery card's morph ADD →
/// qty-stepper interaction, adapted for medical: Rx badge overlay, product
/// form + pack line instead of veg-dot, and no multi-store fan-out.
class MedicalProductCard extends StatelessWidget {
  final MedicalCardProduct product;
  final MedicalCartBusiness businessCtx;

  MedicalProductCard({
    super.key,
    required this.product,
    required this.businessCtx,
  });

  MedicalCartController get _cart =>
      getOrPut(() => MedicalCartController(), permanent: true);

  MedicalCardVariant? get _defaultVariant =>
      product.variants.isEmpty ? null : product.variants.first;

  @override
  Widget build(BuildContext context) {
    final variant = _defaultVariant;

    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 0.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 9.0,
                vertical: SizeConfig.size6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    product.name ?? '',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  _rxAndPackRow(),
                  SizedBox(height: SizeConfig.size6),
                  if (variant != null) _priceRow(variant),
                  SizedBox(height: SizeConfig.size8),
                  _buildAddButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image with only the "+N packs" overlay (Rx moves inline) ─────────
  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: SizedBox(
            height: SizeConfig.size140,
            width: double.infinity,
            child: _fallbackImage(_bestImageUrl()),
          ),
        ),
        if (product.variants.length > 1)
          Positioned(bottom: 8, right: 8, child: _variantsBadge()),
      ],
    );
  }

  String? _bestImageUrl() {
    if ((product.imageUrl ?? '').isNotEmpty) return product.imageUrl;
    for (final v in product.variants) {
      if ((v.imageUrl ?? '').isNotEmpty) return v.imageUrl;
    }
    return null;
  }

  Widget _variantsBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.blackMite,
            borderRadius: BorderRadius.circular(6),
          ),
          child: CustomText(
            '+${product.variants.length} Variants',
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.whiteFE,
          ),
        ),
      ),
    );
  }

  // Inline row mirroring grocery's veg-dot + quantity pill — but the leading
  // slot is the Rx badge (only shown when the product is prescription-only)
  // and the trailing pill is the pack label ("Strip of 15", "60 ml", etc.).
  Widget _rxAndPackRow() {
    final v = _defaultVariant;
    final packParts = <String>[];
    if ((product.form ?? '').isNotEmpty) packParts.add(product.form!);
    if (v != null && (v.variantName ?? '').isNotEmpty)
      packParts.add(v.variantName!);
    final packLabel = packParts.join(' · ');

    final children = <Widget>[];
    if (product.isPrescriptionRequired) {
      children.add(_rxDot());
      if (packLabel.isNotEmpty) children.add(SizedBox(width: SizeConfig.size6));
    }
    if (packLabel.isNotEmpty) {
      children.add(
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(width: 0.5, color: AppColors.greyE5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: CustomText(
              packLabel,
              fontSize: 11,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    if (children.isEmpty) return const SizedBox(height: 0);
    return Row(children: children);
  }

  /// Small red "Rx" chip in a matching outlined box — same visual weight
  /// as grocery's veg-dot so the row reads consistently across services.
  Widget _rxDot() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.red, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: CustomText(
        'Rx',
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: AppColors.red,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _priceRow(MedicalCardVariant v) {
    final selling = (v.sellingPrice ?? 0).toDouble();
    final mrp = (v.mrp ?? 0).toDouble();
    final disc = v.discountPct;
    return PriceRow(
      sellingPrice: '${AppConstants.rupeeSymbol}${_fmt(selling)}',
      mrp: mrp > 0 ? '${AppConstants.rupeeSymbol}${_fmt(mrp)}' : '',
      discount: disc > 0 ? '$disc% off' : null,
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  // ── ADD button that morphs to stepper (single-variant products) ─────
  Widget _buildAddButton(BuildContext context) {
    final variant = _defaultVariant;
    if (variant == null) return const SizedBox.shrink();
    final isMulti = product.variants.length > 1;

    return Obx(() {
      // For multi-variant products, treat the card as "added" when ANY of the
      // product's variants is in the cart, and open the sheet to modify.
      final anyInCart =
          product.variants.any((v) => _cart.contains(v.variantId));
      final singleQty = _cart.getQuantity(variant.variantId);

      if (!isMulti && singleQty > 0) return _stepper(context, variant);

      final active = anyInCart;
      final color = active ? AppColors.green00 : AppColors.primaryColor;
      final label = active
          ? (isMulti ? '${_addedVariantCount()} added' : 'ADDED')
          : 'ADD';
      final icon = active ? Icons.check_rounded : Icons.add_rounded;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: SizeConfig.size32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (isMulti) {
              _openSheet(context);
            } else {
              _addSingle(variant);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child:
                    Icon(icon, key: ValueKey(active), size: 14, color: color),
              ),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: CustomText(
                  label,
                  key: ValueKey(label),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  int _addedVariantCount() {
    int n = 0;
    for (final v in product.variants) {
      if (_cart.contains(v.variantId)) n++;
    }
    return n;
  }

  Widget _stepper(BuildContext context, MedicalCardVariant v) {
    return Container(
      height: SizeConfig.size32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.green00.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.green00, width: 1),
      ),
      child: Obx(() {
        final qty = _cart.getQuantity(v.variantId);
        return Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _cart.removeOne(v.variantId),
                child: Center(
                  child: Icon(
                    qty == 1
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    color: qty == 1 ? AppColors.red : AppColors.green00,
                    size: 16,
                  ),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 26),
              alignment: Alignment.center,
              child: CustomText(
                '$qty',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w900,
                color: AppColors.green00,
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _addSingle(v),
                child: Center(
                  child: Icon(Icons.add_rounded,
                      color: AppColors.green00, size: 16),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _addSingle(MedicalCardVariant v) {
    if (!_ensureSameBusiness()) return;
    _cart.addLine(
      MedicalCartLine(
        variantId: v.variantId,
        productId: product.productId,
        inventoryId: v.inventoryId,
        productName: product.name,
        brand: product.brand,
        variantName: v.variantName,
        productForm: product.form,
        isPrescriptionRequired: product.isPrescriptionRequired,
        mrp: v.mrp,
        sellingPrice: v.sellingPrice,
        imageUrl: (v.imageUrl ?? '').isNotEmpty ? v.imageUrl : product.imageUrl,
      ),
      businessCtx: businessCtx,
    );
  }

  /// Cross-business guard. If the cart already has items from a different
  /// pharmacy, ask before wiping. Returns true when it is safe to proceed.
  bool _ensureSameBusiness() {
    final existing = _cart.business.value;
    if (existing == null) return true;
    if (existing.businessId == businessCtx.businessId) return true;

    Get.dialog(
      AlertDialog(
        title: CustomText('Start a new cart?',
            fontSize: SizeConfig.medium, fontWeight: FontWeight.w800),
        content: CustomText(
          AppStrings.cartWillBeCleared.tr,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomText('Cancel', color: AppColors.secondaryTextColor),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              Get.back();
              _cart.clearAll();
            },
            child: CustomText('Clear cart', color: AppColors.white),
          ),
        ],
      ),
    );
    return false;
  }

  // ── Variants bottom sheet ────────────────────────────────────────────
  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommonDraggableBottomSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        backgroundColor: AppColors.whiteF1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size10,
          bottom: 0,
        ),
        builder: (scrollController) => _VariantsSheet(
          scrollController: scrollController,
          product: product,
          businessCtx: businessCtx,
          cart: _cart,
          onGuard: _ensureSameBusiness,
        ),
      ),
    );
  }

  Widget _fallbackImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.whiteF3,
        alignment: Alignment.center,
        child: Icon(Icons.medical_services_outlined,
            color: AppColors.primaryColor.withValues(alpha: 0.4), size: 36),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => Container(color: AppColors.whiteF3),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.whiteF3,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined,
            color: Colors.grey.shade400, size: 32),
      ),
    );
  }
}

/// Bottom sheet listing every pack size of a product. Each row has its own
/// stepper that mutates the cart directly (no draft/save round-trip — the
/// grocery draft pattern felt heavy for pharmacy carts with 1-2 packs).
class _VariantsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final MedicalCardProduct product;
  final MedicalCartBusiness businessCtx;
  final MedicalCartController cart;
  final bool Function() onGuard;

  const _VariantsSheet({
    required this.scrollController,
    required this.product,
    required this.businessCtx,
    required this.cart,
    required this.onGuard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.secondaryTextColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Row(
          children: [
            if (product.isPrescriptionRequired) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.red, width: 0.6),
                ),
                child: CustomText('Rx',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.red),
              ),
              SizedBox(width: SizeConfig.size6),
            ],
            Expanded(
              child: CustomText(
                product.name ?? 'Available packs',
                fontWeight: FontWeight.w800,
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const CloseButton(),
          ],
        ),
        if ((product.brand ?? '').isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: CustomText(
              '${product.brand}${(product.form ?? '').isNotEmpty ? ' · ${product.form}' : ''}',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        SizedBox(height: SizeConfig.size10),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            itemCount: product.variants.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size8),
            itemBuilder: (_, i) => _variantTile(context, product.variants[i]),
          ),
        ),
      ],
    );
  }

  Widget _variantTile(BuildContext context, MedicalCardVariant v) {
    final selling = (v.sellingPrice ?? 0).toDouble();
    final mrp = (v.mrp ?? 0).toDouble();
    final disc = v.discountPct;
    final imageUrl =
        (v.imageUrl ?? '').isNotEmpty ? v.imageUrl : product.imageUrl;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? Container(
                      color: AppColors.whiteF3,
                      alignment: Alignment.center,
                      child: Icon(Icons.medical_services_outlined,
                          size: 22, color: AppColors.primaryColor),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) =>
                          Container(color: AppColors.whiteF3),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.whiteF3,
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image_outlined,
                            size: 22, color: Colors.grey.shade400),
                      ),
                    ),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  v.variantName ?? 'Pack',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 4),
                PriceRow(
                  sellingPrice:
                      '${AppConstants.rupeeSymbol}${selling.toStringAsFixed(0)}',
                  mrp: mrp > 0
                      ? '${AppConstants.rupeeSymbol}${mrp.toStringAsFixed(0)}'
                      : '',
                  discount: disc > 0 ? '$disc% off' : null,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Obx(() {
            final qty = cart.getQuantity(v.variantId);
            if (qty == 0) return _addChip(v);
            return _sheetStepper(v, qty);
          }),
        ],
      ),
    );
  }

  Widget _addChip(MedicalCardVariant v) {
    return InkWell(
      onTap: () {
        if (!onGuard()) return;
        cart.addLine(
          MedicalCartLine(
            variantId: v.variantId,
            productId: product.productId,
            inventoryId: v.inventoryId,
            productName: product.name,
            brand: product.brand,
            variantName: v.variantName,
            productForm: product.form,
            isPrescriptionRequired: product.isPrescriptionRequired,
            mrp: v.mrp,
            sellingPrice: v.sellingPrice,
            imageUrl:
                (v.imageUrl ?? '').isNotEmpty ? v.imageUrl : product.imageUrl,
          ),
          businessCtx: businessCtx,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 3),
            CustomText('ADD',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _sheetStepper(MedicalCardVariant v, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.green00.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green00, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => cart.removeOne(v.variantId),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Icon(
                  qty == 1
                      ? Icons.delete_outline_rounded
                      : Icons.remove_rounded,
                  size: 15,
                  color: qty == 1 ? AppColors.red : AppColors.green00,
                ),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            alignment: Alignment.center,
            child: CustomText('$qty',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w900,
                color: AppColors.green00),
          ),
          InkWell(
            onTap: () {
              if (!onGuard()) return;
              cart.addLine(
                MedicalCartLine(
                  variantId: v.variantId,
                  productId: product.productId,
                  inventoryId: v.inventoryId,
                  productName: product.name,
                  brand: product.brand,
                  variantName: v.variantName,
                  productForm: product.form,
                  isPrescriptionRequired: product.isPrescriptionRequired,
                  mrp: v.mrp,
                  sellingPrice: v.sellingPrice,
                  imageUrl: (v.imageUrl ?? '').isNotEmpty
                      ? v.imageUrl
                      : product.imageUrl,
                ),
                businessCtx: businessCtx,
              );
            },
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child:
                    Icon(Icons.add_rounded, size: 15, color: AppColors.green00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
