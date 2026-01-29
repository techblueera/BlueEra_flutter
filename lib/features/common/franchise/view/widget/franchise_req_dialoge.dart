import 'dart:ui';

import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';

class PartnerUnavailableDialog extends StatelessWidget {
  const PartnerUnavailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(context);
        Navigator.pop(context);
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                  image: AssetImage(
                      AppImageAssets.chatBgLight,
                  ),
                  fit: BoxFit.cover
              )
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// 🔴 Sorry Box
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(SizeConfig.size16),
                    decoration: BoxDecoration(
                      color: AppColors.redE4,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        CustomText(
                          'Sorry!',
                          fontSize: SizeConfig.extraLarge22,
                          fontWeight: FontWeight.w400,
                          color: AppColors.redLite,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        CustomText(
                          'Sorry! BlueEra Partners are not available in your PIN '
                              'code at the moment. Don’t worry—we’ll notify you as '
                              'soon as services start in your area.',
                          textAlign: TextAlign.center,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          height: 1.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: SizeConfig.size30),

              /// ⚪ Become Partner Box
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(SizeConfig.size16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      // border: Border.all(color: AppColors.greyLite),
                    ),
                    child: Column(
                      children: [
                        CustomText(
                          'Become A partner',
                          fontSize: SizeConfig.extraLarge,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        CustomText(
                          'If you’re interested in becoming a BlueEra Partner '
                              '(Franchise) for this PIN code (${LocationService.userCurrentAddress.value.postalCode}), please apply here.',
                          textAlign: TextAlign.center,
                          fontSize: SizeConfig.small,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: SizeConfig.size12),

              /// 🔘 Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                      title: 'Back',
                      isValidate: false,
                      radius: 10,
                      textColor: AppColors.black,
                      onTap: (){
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      bgColor: AppColors.greyLite,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CustomBtn(
                      title: 'Apply Here',
                      isValidate: true,
                      radius: 10,
                      onTap: () {
                        Get.to(() => CommonWebView(
                          urlLink: takeFranchise,
                          urlTitle: AppStrings.applyForFranchise,
                        ));
                      },
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}