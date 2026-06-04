import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/hmp_cart_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Cart page for a single home made product seller. Finds the cart controller
/// the list screen registered, lists the chosen products with qty steppers,
/// and places the order.
class HmpCartScreen extends StatelessWidget {
  final EarnProfileModel store;

  const HmpCartScreen({super.key, required this.store});

  // App primary color combination (theme-aligned accent for this flow).
  static const Color _primary = AppColors.primaryColor; // 0xFF0086FF
  static const Color _primaryDeep = AppColors.blue5CAF; // 0xFF005CAF

  HmpCartController get _controller => getOrPut(() => HmpCartController());

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
        title: CustomText(
          'Your Cart',
          fontSize: SizeConfig.extraLarge,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
      ),
      body: Obx(() {
        // touch the reactive map so this rebuilds on every +/- / removal
        final count = controller.quantities.length;
        if (count == 0) {
          return _emptyState();
        }
        final lines = controller.lines;
        return Column(
          children: [
            _storeBanner(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _cartLine(controller, lines[i]),
              ),
            ),
            _summaryBar(context, controller),
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
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _storeBanner() {
    return Container(
      width: double.infinity,
      color: _primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.storefront_rounded, size: 16, color: _primary),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              store.serviceName ?? 'Home Made Products',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartLine(HmpCartController controller, GetProductData item) {
    final mrp = HmpCartController.mrpOf(item);
    final sp = HmpCartController.sellingPriceOf(item);
    final imageUrl = HmpCartController.imageOf(item);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5, width: 0.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
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
                  HmpCartController.nameOf(item),
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
                      '${AppConstants.rupeeSymbol}${sp.toStringAsFixed(0)}',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    if (mrp > sp && mrp > 0) ...[
                      const SizedBox(width: 6),
                      CustomText(
                        '${AppConstants.rupeeSymbol}${mrp.toStringAsFixed(0)}',
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
          _stepper(controller, item),
        ],
      ),
    );
  }

  Widget _stepper(HmpCartController controller, GetProductData item) {
    final qty = controller.qty(HmpCartController.idOf(item));
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
            onTap: () => controller.remove(item),
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
              final seller = controller.store.value;
              if (seller != null) controller.add(item, seller);
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
        width: 34,
        height: 34,
        child: Center(child: Icon(icon, color: color, size: 16)),
      ),
    );
  }

  Widget _summaryBar(BuildContext context, HmpCartController controller) {
    final total = controller.totalPrice;
    final savings = controller.totalSavings;
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
              if (savings > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E7D34).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.savings_rounded,
                          size: 15, color: Color(0xFF1E7D34)),
                      const SizedBox(width: 6),
                      CustomText(
                        'You save ${AppConstants.rupeeSymbol}${savings.toStringAsFixed(0)} on this order',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E7D34),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          '${controller.totalItems} ${controller.totalItems == 1 ? 'item' : 'items'}',
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
                    child: Obx(() {
                      final loading = controller.isPlacingOrder.value;
                      return InkWell(
                        onTap: loading ? null : controller.placeOrder,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryDeep, _primary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : CustomText(
                                  'Place Order',
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w800,
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
  }
}
