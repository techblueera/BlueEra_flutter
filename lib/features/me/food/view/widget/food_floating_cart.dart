import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/view/admin/food_cart_screen.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Floating selection summary used on both the snap-search and
/// product-selection screens. Tapping the CTA opens the
/// [FoodCartScreen] review-and-publish flow.
///
/// Sits as a [Positioned] overlay inside a [Stack] so the user keeps
/// seeing newly-ticked variants accumulate in the cart without having
/// to reopen the variant bottom sheet. Slides in from the bottom the
/// first time the cart is non-empty and fades out when emptied.
class FoodFloatingCart extends StatelessWidget {
  /// Approximate height the cart occupies once visible. Callers can use
  /// this to pad their scroll content so the last item stays reachable
  /// above the floating cart.
  static const double reservedSpace = 92;

  final FoodServiceController controller;
  final bool isSnapSearch;

  const FoodFloatingCart({
    super.key,
    required this.controller,
    this.isSnapSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final productCount = controller.selectedVariantsMap.keys.length;
      final totalVariantsCount = controller.selectedVariantsMap.values
          .fold<int>(0, (sum, list) => sum + list.length);

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: productCount == 0
            ? const SizedBox.shrink(key: ValueKey('cart_empty'))
            : _buildCart(productCount, totalVariantsCount),
      );
    });
  }

  Widget _buildCart(int productCount, int totalVariantsCount) {
    return Padding(
      key: const ValueKey('cart_visible'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.zero,
            child: Row(
              children: [
                _cartBadge(productCount),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        '$productCount Products  •  $totalVariantsCount Variants',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        'Tap review to set prices and publish',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 130,
                  height: 40,
                  child: PositiveCustomBtn(
                    onTap: () => Get.to(
                      () => FoodCartScreen(isSnapSearch: isSnapSearch),
                    ),
                    title: 'Review & Publish',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartBadge(int productCount) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.shopping_cart_outlined,
              color: AppColors.primaryColor, size: 22),
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: CustomText(
                  '$productCount',
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
