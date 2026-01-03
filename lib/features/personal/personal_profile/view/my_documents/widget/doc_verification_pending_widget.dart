import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';

class DocumentVerificationPendingWidget extends StatelessWidget {
  final String documentName;
  // final VoidCallback? onOkayTap;

  const DocumentVerificationPendingWidget({
    super.key,
    required this.documentName,
    // this.onOkayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Icon
        LocalAssets(
          imagePath: AppIconAssets.storeWatch,
          height: 50,
          width: 50,
          imgColor: AppColors.yellow,
        ),

        SizedBox(height: SizeConfig.size15),

        // 2. Title
        CustomText(
          "Verification Pending",
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),

        SizedBox(height: SizeConfig.size10),

        // 3. Rich Description
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              fontFamily: 'Manrope', // Add your font family if CustomText uses one
            ),
            children: [
              const TextSpan(text: "Your "),

              TextSpan(
                text: documentName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),

              const TextSpan(
                text: " has been uploaded and is currently under review. Please wait for the admin to approve it.",
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        // if(onOkayTap!=null)...[
          SizedBox(height: SizeConfig.size20),

          CustomBtn(
            // onTap: onOkayTap,
            onTap: ()=> Get.back(),
            title: "Okay",
            radius: 10.0,
            height: SizeConfig.size40,
            width: SizeConfig.size120,
            bgColor: AppColors.primaryColor,
            textColor: AppColors.white,
          )
        // ]

      ],
    );
  }
}