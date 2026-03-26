import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';

class ViewCartFooter extends StatelessWidget {
  const ViewCartFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GrocerySelfPickupConsumerController>();

    return Obx(() {
      final int itemCount = controller.selectedGroceriesVariants.length;
      final double totalPrice = controller.totalSellingPrice;

      // Hide footer if no items are selected
      if (itemCount == 0) return const SizedBox.shrink();

      return Material(
        elevation: 8.0,
        color: AppColors.white,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size15,
              vertical: SizeConfig.size15,
            ),
            child: Row(
              children: [
                // --- Price & Count Display (Non-clickable) ---
                Expanded(
                  child: CustomBtn(
                    onTap: null,
                    isValidate: false,
                    radius: SizeConfig.size10,
                    // FittedBox ensures long prices don't break the UI
                    title: '₹${totalPrice.toStringAsFixed(2)}, $itemCount Products',
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    bgColor: AppColors.white,
                  ),
                ),

                SizedBox(width: SizeConfig.size10),

                // --- View Cart Action ---
                CustomBtn(
                  onTap: () {
                    Get.toNamed(
                      RouteHelper.getGroceryCartScreenRoute(),
                      arguments: {ApiKeys.argIsDeliveredByRider: true},
                    );
                  },
                  isValidate: true,
                  radius: SizeConfig.size10,
                  title: 'View Cart',
                  width: SizeConfig.size110, // Slightly wider for better touch target
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}