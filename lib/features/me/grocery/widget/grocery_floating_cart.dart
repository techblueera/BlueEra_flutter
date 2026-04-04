import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryFloatingCart extends StatelessWidget {
  final GroceryController controller;

  const GroceryFloatingCart({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedGroceries;
      final displayImages = selected.take(3).map((p) {
        if (p.images?.isNotEmpty ?? false) {
          return p.images!.first.url;
        }
        return null;
      }).toList();

      return FloatingCartWidget(
        itemCount: selected.length,
        displayImages: displayImages,
        onTap: () => Get.toNamed(RouteHelper.getAddGroceryScreenRoute()),
      );
    });
  }
}
