import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/add_vehicle_variant_screen_v3.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The add-flow basket pill — "3 vehicles →" — routing to review & publish.
///
/// Shared by every screen a merchant can add from, which is the point: the
/// rails on the add landing and the trim list behind "More" feed the SAME
/// basket, so whichever way a vehicle was found, it ends up in one review
/// screen and one publish. The "More" branch used to run a separate
/// colour-screen → form-screen chain that published on its own, so the two
/// halves of the same feature behaved differently.
///
/// Hidden while the basket is empty, exactly like grocery's floating cart.
class VehicleBasketFabV3 extends StatelessWidget {
  final VehicleV3Controller controller;

  const VehicleBasketFabV3({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.basket.length;
      if (count == 0) return const SizedBox.shrink();
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Get.to(() => const AddVehicleVariantScreenV3()),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size20,
              vertical: SizeConfig.size12,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car_filled_outlined,
                    color: AppColors.white, size: 20),
                SizedBox(width: SizeConfig.size8),
                CustomText(
                  count == 1 ? '1 vehicle' : '$count vehicles',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
                SizedBox(width: SizeConfig.size8),
                Icon(Icons.arrow_forward_rounded,
                    color: AppColors.white, size: 18),
              ],
            ),
          ),
        ),
      );
    });
  }
}
