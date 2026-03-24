import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_customer_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonCartIcon extends StatelessWidget {
  final bool argIsDeliveredByRider;
  const CommonCartIcon({super.key, required this.argIsDeliveredByRider});

  @override
  Widget build(BuildContext context) {
    // Accessing the grocery controller
    final controller = Get.find<GroceryCustomerController>();

    return Obx(() {
      final int itemCount = controller.selectedGroceriesVariants.length;

      if (itemCount == 0) {
        return Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: InkWell(
            onTap: () {
              // Optional: Add search or "cart is empty" toast
            },
            child: const Icon(Icons.search), // Shows search icon when cart is empty
          ),
        );
      }

      return InkWell(
        onTap: () => Get.toNamed(
            RouteHelper.getYourAddToCardScreenRoute(),
            arguments: {
             ApiKeys.argIsDeliveredByRider: argIsDeliveredByRider
           }
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The Cart Icon
              LocalAssets(
                imagePath: AppIconAssets.cartIcon,
                height: SizeConfig.size24,
                width: SizeConfig.size24,
              ),

              // The Red Badge Count
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  height: SizeConfig.size16,
                  width: SizeConfig.size16,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: CustomText(
                        '$itemCount',
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}