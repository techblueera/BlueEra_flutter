import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_customer_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GoToCartButton extends StatelessWidget {
  const GoToCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroceryCustomerController>();

    return Obx(() {
      final int itemCount = controller.selectedGroceriesVariants.length;

      if (itemCount == 0) return const SizedBox.shrink();

      return Material(
        elevation: 8.0,
        shadowColor: Colors.black45,
        child: Container(
          color: AppColors.white,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size15,
              vertical: SizeConfig.size10
          ),
          child: SafeArea(
            child: CustomBtn(
              onTap: () => Get.toNamed(
                RouteHelper.getGroceryCartScreenRoute(),
                arguments: {ApiKeys.argIsDeliveredByRider: false},
              ),
              isValidate: true,
              radius: SizeConfig.size10,
              title: 'View Cart ($itemCount ${itemCount > 1 ? 'Items' : 'Item'})',
              width: double.infinity,
            ),
          ),
        ),
      );
    });
  }
}