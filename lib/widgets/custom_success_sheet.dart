import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CustomSuccessSheet extends StatelessWidget {
  const CustomSuccessSheet(
      {super.key,
        required this.title,
        required this.subTitle,
        required this.buttonText,
        required this.onPress});

  final String title;
  final String subTitle;
  final String buttonText;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.grey66,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12)),
      width: SizeConfig.screenWidth,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppIconAssets.circleCheck,
            height: 80,
            width: 80,
          ),
          SizedBox(height: SizeConfig.size15),
          CustomText(
            title,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.screenWidth * .06,
            textAlign: TextAlign.center,
          ),
          if (subTitle.isNotEmpty) SizedBox(height: SizeConfig.size15),
          if (subTitle.isNotEmpty)
            CustomText(
              subTitle,
              textAlign: TextAlign.center,

                  color: AppColors.black28,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.screenWidth * .04,
            ),
          SizedBox(height: SizeConfig.size30),
          CustomBtn(
              title: buttonText,
              onTap: onPress,
              isValidate: true)
        ],
      ),
    );
  }
}