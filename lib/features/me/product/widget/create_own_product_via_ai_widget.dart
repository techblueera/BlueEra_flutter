import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateOwnProductViaAiWidget extends StatelessWidget {
  final ProviderType providerType;

  const CreateOwnProductViaAiWidget({
    super.key,
    required this.providerType,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        RouteHelper.getAddProductViaAiStep1Route(),
        arguments: {
          ApiKeys.id: businessId,
          ApiKeys.providerType: providerType,
        },
      ),
      child: Container(
        height: SizeConfig.size30,
        margin: EdgeInsets.only(right: SizeConfig.size20),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add,
              color: AppColors.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.createOwn,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}