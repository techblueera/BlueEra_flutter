import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/hmf_cart_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Multi-store cart for the home made food flow (Zomato-style). Lists every
/// kitchen the user has items from, each as its own card with a stepper list
/// and its **own Checkout** button. A bottom **Checkout All** bar appears when
/// there's more than one kitchen.
class HmfCartScreen extends StatelessWidget {
  const HmfCartScreen({super.key});

  // App primary color combination (theme-aligned accent for this flow).
  static const Color _primary = AppColors.primaryColor; // 0xFF0086FF
  static const Color _primaryDeep = AppColors.blue5CAF; // 0xFF005CAF
  static const Color _green = Color(0xFF1E7D34);

  HmfCartController get _controller => getOrPut(() => HmfCartController());

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.mainTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Obx(() {
          final _ = controller.quantities.length; // subscribe
          final n = controller.storeCount;
          return CustomText(
            n > 1 ? 'Your Carts ($n)' : 'Your Cart',
            fontSize: SizeConfig.extraLarge,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          );
        }),
      ),
      body: Obx(() {
        // touch the reactive map so this rebuilds on every +/- / removal,
        // and placingKey so the buttons reflect loading.
        final _ = controller.quantities.length;
        final __ = controller.placingKey.value;
        if (controller.isEmpty) return _emptyState();

        final keys = controller.storeKeys;
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: keys.length,
                itemBuilder: (_, i) => _storeCart(controller, keys[i]),
              ),
            ),
            if (controller.storeCount > 1) _checkoutAllBar(controller),
          ],
        );
      }),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
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
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  // ── One kitchen's cart card ────────────────────────────────────────────────
  Widget _storeCart(HmfCartController c, String key) {
    final store = c.storeOf(key);
    final lines = c.linesOf(key);
    final subtotal = c.priceOf(key);
    final savings = c.savingsOf(key);
    final count = c.itemCountOf(key);
    final placing = c.placingKey.value == key;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Kitchen header ──
          Container(
            color: _primary.withValues(alpha: 0.05),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _storeAvatar(store),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        store?.serviceName ?? 'Home Kitchen',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        '$count ${count == 1 ? 'item' : 'items'}',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
                // Clear this kitchen's cart.
                InkWell(
                  onTap: () => c.clearStore(key),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.secondaryTextColor),
                  ),
                ),
              ],
            ),
          ),

          // ── Items ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                for (int i = 0; i < lines.length; i++) ...[
                  if (i > 0)
                    Divider(height: 18, color: AppColors.greyE5, thickness: 0.6),
                  _cartLine(c, store, lines[i]),
                ],
              ],
            ),
          ),

          // ── Savings + per-store checkout ──
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.greyE5, width: 0.6),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                if (savings > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.savings_rounded,
                            size: 14, color: _green),
                        const SizedBox(width: 6),
                        CustomText(
                          'You save ${AppConstants.rupeeSymbol}${savings.toStringAsFixed(0)}',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Subtotal',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            '${AppConstants.rupeeSymbol}${subtotal.toStringAsFixed(0)}',
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _checkoutButton(
                      label: 'Checkout',
                      loading: placing,
                      onTap: () => c.placeOrderForStore(key),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeAvatar(EarnProfileModel? store) {
    final logo = store?.serviceLogo ?? '';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primary.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: logo.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.cover,
              width: 38,
              height: 38,
              placeholder: (_, __) =>
                  Container(color: _primary.withValues(alpha: 0.10)),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.storefront_rounded, size: 18, color: _primary),
            )
          : const Icon(Icons.storefront_rounded, size: 18, color: _primary),
    );
  }

  // ── One item row ───────────────────────────────────────────────────────────
  Widget _cartLine(HmfCartController c, EarnProfileModel? store,
      FoodItemModel item) {
    final mrp = double.tryParse(item.mrpPrice) ?? 0;
    final sp = double.tryParse(item.sellingPrice) ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                item.foodName,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  CustomText(
                    '${AppConstants.rupeeSymbol}${item.sellingPrice}',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  if (mrp > sp && mrp > 0) ...[
                    const SizedBox(width: 6),
                    CustomText(
                      '${AppConstants.rupeeSymbol}${item.mrpPrice}',
                      fontSize: 11,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.secondaryTextColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _stepper(c, store, item),
      ],
    );
  }

  Widget _stepper(
      HmfCartController c, EarnProfileModel? store, FoodItemModel item) {
    final qty = c.qty(item.id);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _primary.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(
            icon: qty == 1 ? Icons.delete_outline_rounded : Icons.remove,
            color: qty == 1 ? AppColors.red : _primary,
            onTap: () => c.remove(item),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            alignment: Alignment.center,
            child: CustomText(
              '$qty',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ),
          _stepBtn(
            icon: Icons.add,
            color: _primary,
            onTap: () {
              if (store != null) c.add(item, store);
            },
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(child: Icon(icon, color: color, size: 16)),
      ),
    );
  }

  // ── Per-store checkout button ──────────────────────────────────────────────
  Widget _checkoutButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primaryDeep, _primary]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : CustomText(
                label,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
      ),
    );
  }

  // ── Bottom "Checkout All" bar (only with >1 kitchen) ───────────────────────
  Widget _checkoutAllBar(HmfCartController c) {
    final total = c.totalPrice;
    final placingAll = c.placingKey.value == '__all__';
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
                      '${c.totalItems} ${c.totalItems == 1 ? 'item' : 'items'} · ${c.storeCount} kitchens',
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
                child: _checkoutButton(
                  label: 'Checkout All',
                  loading: placingAll,
                  onTap: c.placeAllOrders,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
