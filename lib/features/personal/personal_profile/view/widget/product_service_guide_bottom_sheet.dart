import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductServiceGuideBottomSheet extends StatelessWidget {
  ProductServiceGuideBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
          top: 5
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.homeMadeProducts,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          SizedBox(height: SizeConfig.size16),
          HorizontalVideoPlayer(),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            "${AppStrings.earnWithHomeMadeTitle.tr} ${AppStrings.earnWithHomeMadeSubtitle.tr}",
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size20),

          CustomBtn(
            height: SizeConfig.size40,
            title: AppStrings.startListingNow,
            onTap: () {
              if (userProfessionGlobal == DELIVERY_RIDER) {
                Get.offNamedUntil(
                  RouteHelper.getAddProductScreenRoute(),
                  ModalRoute.withName(RouteHelper.getEarnServiceAvailableOptionsScreenRoute()),
                  arguments: {
                    ApiKeys.id: userId,
                    ApiKeys.providerType: ProviderType.user,
                  },
                );
              } else {
                Get.offNamedUntil(
                  RouteHelper.getAddProductScreenRoute(),
                  ModalRoute.withName(RouteHelper.getEarnServiceScreenRoute()),
                  arguments: {
                    ApiKeys.id: userId,
                    ApiKeys.providerType: ProviderType.user,
                  },
                );

              }


            },
            bgColor: AppColors.primaryColor,
            textColor: AppColors.white,
            radius: 10.0,
          ),

          SizedBox(height: SizeConfig.size16),
        ],
      ),
    );
  }
}

