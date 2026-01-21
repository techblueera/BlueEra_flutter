import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';

class PartnerUnavailableDialog extends StatelessWidget {
  const PartnerUnavailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Stack(
            children: [
              // BACKGROUND
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LocalAssets(imagePath: AppImageAssets.chatBgLight,
                  height: 390,
                  width: double.infinity,
                  boxFix: BoxFit.cover,
                ),
              ),

              // CONTENT
              Padding(
                padding: EdgeInsets.all(SizeConfig.size16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: SizeConfig.size8),

                    /// 🔴 Sorry Box
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(SizeConfig.size16),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CustomText(
                            'Sorry!',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.red,
                          ),
                          SizedBox(height: SizeConfig.size10),
                          CustomText(
                            'Sorry! BlueEra Partners are not available in your PIN '
                                'code at the moment. Don’t worry—we’ll notify you as '
                                'soon as services start in your area.',
                            textAlign: TextAlign.center,
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: SizeConfig.size30),

                    /// ⚪ Become Partner Box
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(SizeConfig.size16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        // border: Border.all(color: AppColors.greyLite),
                      ),
                      child: Column(
                        children: [
                          CustomText(
                            'Become A partner',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: SizeConfig.size10),
                          CustomText(
                            'If you’re interested in becoming a BlueEra Partner '
                                '(Franchise) for this PIN code (544115), please apply here.',
                            textAlign: TextAlign.center,
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: SizeConfig.size24),

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
                          ),
                        ),
                        SizedBox(width: SizeConfig.size12),
                        Expanded(
                          child: CustomBtn(
                            title: 'Apply Here',
                            isValidate: true,
                            radius: 10,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.size12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}