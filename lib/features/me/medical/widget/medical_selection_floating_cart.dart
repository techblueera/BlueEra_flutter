import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The **merchant-side** selection cart on `MedicalProductSelectionScreen` —
/// the pharmacy owner picking catalogue items to publish. Counts what's
/// selected and hands off to the variant screen. Mirrors `GroceryFloatingCart`.
///
/// Not to be confused with `MedicalFloatingCart`, which is the **customer's**
/// checkout cart (MedicalCartController, prescriptions, totals, Checkout). Two
/// different jobs on two different sides of the app — hence the longer name
/// here rather than shadowing that one.
class MedicalSelectionFloatingCart extends StatelessWidget {
  final MedicalController controller;

  const MedicalSelectionFloatingCart({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedMedicalProducts;
      final displayImages = selected.take(3).map((p) {
        if (p.images?.isNotEmpty ?? false) {
          return p.images!.first.url;
        }
        return null;
      }).toList();

      return FloatingCartWidget(
        itemCount: selected.length,
        displayImages: displayImages,
        // Straight to the variant screen. The old AddMedicalScreen sat in
        // between as a review grid, but the variant screen already lists every
        // selected product — so it was one tap of pure friction.
        onTap: () => Get.toNamed(RouteHelper.getAddMedicalVariantScreenRoute()),
      );
    });
  }
}
