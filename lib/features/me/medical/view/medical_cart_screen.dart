import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalCartScreen extends StatelessWidget {
  const MedicalCartScreen({super.key});

  static const Color _primary = AppColors.primaryColor;
  static const Color _primaryDeep = AppColors.blue5CAF;

  @override
  Widget build(BuildContext context) {
    final cart = getOrPut(() => MedicalCartController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.whiteF1,
      appBar: CommonBackAppBar(title: 'Your Cart'),
      body: Obx(() {
        // Subscribe to add/remove/qty changes so the whole page re-renders.
        // ignore: unused_local_variable
        final _ = cart.cartQuantities.length;
        // ignore: unused_local_variable
        final __ = cart.cartLines.length;

        if (cart.isEmpty) return _emptyState();

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(SizeConfig.size12),
                children: [
                  _storeHeader(cart),
                  SizedBox(height: SizeConfig.size10),
                  ...cart.cartLines.values.map((l) => Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size8),
                        child: _CartRow(line: l, cart: cart),
                      )),
                  SizedBox(height: SizeConfig.size12),
                  _deliveryTypeToggle(cart),
                  SizedBox(height: SizeConfig.size12),
                  _billSummary(cart),
                  if (cart.hasAnyPrescriptionItem) ...[
                    SizedBox(height: SizeConfig.size12),
                    _rxNotice(),
                  ],
                  SizedBox(height: SizeConfig.size12),
                ],
              ),
            ),
            _placeOrderBar(cart),
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
          Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.greyE5),
          const SizedBox(height: 16),
          CustomText(
            'Your cart is empty',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _storeHeader(MedicalCartController cart) {
    final b = cart.business.value;
    if (b == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      child: Row(
        children: [
          CachedAvatarWidget(
            imageUrl: b.logo ?? '',
            size: SizeConfig.size40,
            borderColor: Colors.white,
            borderRadius: SizeConfig.size20,
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  b.businessName,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((b.address ?? '').isNotEmpty) ...[
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: CustomText(
                          b.address!,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Two-option segmented control — self-pickup vs rider delivery. The
  /// chosen value drives the request body's `deliveryType` and the
  /// post-order navigation (rider mode hands off to the confirm screen so
  /// the rider matching stream can take over).
  Widget _deliveryTypeToggle(MedicalCartController cart) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText('Delivery',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor),
          SizedBox(height: SizeConfig.size10),
          Obx(() {
            final selected = cart.deliveryType.value;
            return Row(
              children: [
                Expanded(
                  child: _deliveryOption(
                    label: 'Self-pickup',
                    subtitle: 'Collect from pharmacy',
                    icon: Icons.storefront_rounded,
                    isSelected: selected == MedicalDeliveryType.selfPickup,
                    onTap: () =>
                        cart.setDeliveryType(MedicalDeliveryType.selfPickup),
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: _deliveryOption(
                    label: 'Rider delivery',
                    subtitle: 'Home delivery',
                    icon: Icons.two_wheeler_rounded,
                    isSelected: selected == MedicalDeliveryType.rider,
                    onTap: () => cart.setDeliveryType(MedicalDeliveryType.rider),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _deliveryOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? _primary : AppColors.greyE5;
    final bg = isSelected
        ? _primary.withValues(alpha: 0.08)
        : AppColors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: isSelected ? 1.2 : 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: isSelected ? _primary : AppColors.secondaryTextColor),
                const Spacer(),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? _primary : AppColors.secondaryTextColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            CustomText(label,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            CustomText(subtitle,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _billSummary(MedicalCartController cart) {
    final subtotal = cart.totalSellingPrice;
    final mrp = cart.totalMRP;
    final savings = cart.totalSavings;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText('Bill details',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor),
          SizedBox(height: SizeConfig.size10),
          _billRow('MRP total', mrp, strike: false),
          const SizedBox(height: 6),
          _billRow('Item total', subtotal),
          if (savings > 0) ...[
            const SizedBox(height: 6),
            _billRow('You save', -savings, positive: true),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(height: 0.6, color: AppColors.greyE5),
          ),
          Row(
            children: [
              Expanded(
                child: CustomText('To pay',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w900,
                    color: AppColors.mainTextColor),
              ),
              CustomText(
                '${AppConstants.rupeeSymbol}${subtotal.toStringAsFixed(2)}',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w900,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double value,
      {bool strike = false, bool positive = false}) {
    final display =
        '${AppConstants.rupeeSymbol}${value.abs().toStringAsFixed(2)}';
    final color = positive ? AppColors.green00 : AppColors.mainTextColor;
    return Row(
      children: [
        Expanded(
          child: CustomText(label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor),
        ),
        CustomText(
          positive ? '- $display' : display,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w800,
          color: color,
          decoration: strike ? TextDecoration.lineThrough : null,
        ),
      ],
    );
  }

  Widget _rxNotice() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.red.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.red),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText('Prescription required',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red),
                const SizedBox(height: 2),
                CustomText(
                  'One or more items in your cart need a valid prescription.',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeOrderBar(MedicalCartController cart) {
    final total = cart.totalSellingPrice;
    final items = cart.totalItemsCount;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size12,
              SizeConfig.size16, SizeConfig.size12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      '$items ${items == 1 ? 'item' : 'items'}',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      '${AppConstants.rupeeSymbol}${total.toStringAsFixed(2)}',
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: cart.placeOrder,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_primaryDeep, _primary]),
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
                      AppStrings.placeOrder.tr,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final MedicalCartLine line;
  final MedicalCartController cart;

  const _CartRow({required this.line, required this.cart});

  void _confirmRemove(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final selling = line.sellingValue;
    final mrp = line.mrpValue;
    final hasDiscount = mrp > selling && mrp > 0;
    final discPct = hasDiscount ? (((mrp - selling) / mrp) * 100).round() : 0;
    final imageUrl = line.imageUrl ?? '';

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: imageUrl.isEmpty
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
                        line.productName ?? '',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if ((line.brand ?? '').isNotEmpty ||
                    (line.productForm ?? '').isNotEmpty ||
                    (line.variantName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  CustomText(
                    _subtitle(),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      '${AppConstants.rupeeSymbol}${selling.toStringAsFixed(0)}',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 6),
                      CustomText(
                        '${AppConstants.rupeeSymbol}${mrp.toStringAsFixed(0)}',
                        fontSize: 11,
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
                          color: AppColors.green00.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          '$discPct% off',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green00,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Obx(() {
            final qty = cart.getQuantity(line.variantId);
            return Container(
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryColor, width: 0.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _confirmRemove(context),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(
                          qty == 1
                              ? Icons.delete_outline_rounded
                              : Icons.remove_rounded,
                          size: 15,
                          color:
                              qty == 1 ? AppColors.red : AppColors.primaryColor,
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
                        color: AppColors.mainTextColor),
                  ),
                  InkWell(
                    onTap: () => cart.addLine(line),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(Icons.add_rounded,
                            size: 15, color: AppColors.primaryColor),
                      ),
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

  String _subtitle() {
    final parts = <String>[];
    if ((line.brand ?? '').isNotEmpty) parts.add(line.brand!);
    if ((line.productForm ?? '').isNotEmpty) parts.add(line.productForm!);
    if ((line.variantName ?? '').isNotEmpty) parts.add(line.variantName!);
    return parts.join(' · ');
  }
}
