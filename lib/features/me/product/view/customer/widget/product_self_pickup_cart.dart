import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/view/customer/product_self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductSelfPickupCart extends StatelessWidget {
  final ProductSelfPickupController controller;

  const ProductSelfPickupCart({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        final selected = controller.selectedProductVariants;
        final displayImages = selected.take(3).map((p) {
          final media = p.product.details?.media;
          if (media != null && media.isNotEmpty && media.first.isNotEmpty) {
            return media.first;
          }
          final variants = p.product.sellerClassification?.variants;
          if (variants != null && variants.isNotEmpty) {
            final variantMedia = variants.first.mediaRelatedToVariant;
            if (variantMedia.isNotEmpty && variantMedia.first.isNotEmpty) {
              return variantMedia.first;
            }
          }
          return null;
        }).toList();

        return FloatingCartWidget(
          itemCount: selected.length,
          displayImages: displayImages,
          onTap: () => Get.to(() => const ProductSelfPickUpCartScreen()),
        );
      }),
    );
  }
}
