import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/view/food_self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Floating cart pill for the food self-pickup flow.
///
/// Must be placed as a **direct** `Positioned` child of a `Stack` — it
/// already returns a `Positioned` from build so that `StackParentData`
/// propagation is unambiguous.
class FoodSelfPickupCartBar extends StatelessWidget {
  final FoodSelfPickupController controller;

  const FoodSelfPickupCartBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Obx(() {
        final itemCount = controller.selectedFoodVariants.length;
        if (itemCount == 0) return const SizedBox.shrink();
        return SafeArea(
          child: GestureDetector(
            onTap: () {
              Get.to(()=> const FoodSelfPickUpCartScreen());
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
        );
      }),
    );
  }
}
