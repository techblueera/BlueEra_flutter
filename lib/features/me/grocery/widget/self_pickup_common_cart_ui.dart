import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/Discover/view/self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelfPickupCommonCartUi extends StatelessWidget {
  final RxList selectedVariants;

  const SelfPickupCommonCartUi({
    super.key,
    required this.selectedVariants,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int itemCount = selectedVariants.length;
      if (itemCount == 0) return const SizedBox.shrink();
      return Positioned(
        left: 16,
        right: 16,
        bottom: 20,
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
            //   Get.toNamed(
            //   RouteHelper.getYourAddToCardScreenRoute(),
            // );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelfPickUpCartScreen(deliveryType: 'SELF'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomText(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      fontSize: 13,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  CustomText(
                    'View Cart',
                    fontSize: 16,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}