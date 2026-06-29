import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ORDERS TAB â€” placeholder until product orders ships.
class ManufacturerOrdersTabBody extends StatelessWidget {
  const ManufacturerOrdersTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size40,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              AppStrings.orders.tr,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              AppStrings.comingSoon.tr,
              fontSize: 12,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
