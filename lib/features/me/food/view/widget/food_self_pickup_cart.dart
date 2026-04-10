import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/view/food_self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodSelfPickupCart extends StatelessWidget {
  final FoodSelfPickupController controller;

  const FoodSelfPickupCart({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Obx(() {
          final selected = controller.selectedFoodVariants;
          final displayImages = selected.take(3).map((v) {
            final img = controller.cartProductImages[v.id];
            if (img != null && img.isNotEmpty) return img;
            return null;
          }).toList();

          return FloatingCartWidget(
            itemCount: selected.length,
            displayImages: displayImages,
            onTap: () => Get.to(() => const FoodSelfPickUpCartScreen()),
          );
        }),
      ),
    );
  }
}
