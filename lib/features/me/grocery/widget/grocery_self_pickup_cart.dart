import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GrocerySelfPickupCart extends StatelessWidget {
  final GrocerySelfPickupConsumerController controller;

  const GrocerySelfPickupCart({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Obx(() {
          final selected = controller.selectedGroceriesVariants;
          final displayImages = selected.take(3).map((v) {
            // Try variant-level images first.
            if (v.images?.isNotEmpty ?? false) {
              final url = v.images!.first.url;
              if (url != null && url.isNotEmpty) return url;
            }
            // Fallback to product-level image stored when adding to cart.
            final fallback = controller.cartProductImages[v.sId];
            if (fallback != null && fallback.isNotEmpty) return fallback;
            return null;
          }).toList();

          return FloatingCartWidget(
            itemCount: selected.length,
            displayImages: displayImages,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GrocerySelfPickUpCartScreen(),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
