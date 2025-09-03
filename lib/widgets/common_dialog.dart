import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

commonConformationDialog(
    {required BuildContext context,
    required String text,
    required VoidCallback confirmCallback,
    required VoidCallback cancelCallback,
    bool barrierDismissible = true}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: Get.width,
                  color: AppColors.primaryColor,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                  child: CustomText(
                    AppLocalizations.of(context)!.confirm,
                    color: Colors.white,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: CustomText(
                    text,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                          bgColor: AppColors.white,
                          borderColor: AppColors.primaryColor,
                          textColor: AppColors.primaryColor,
                          onTap: () {
                            confirmCallback();
                          },
                          title: AppLocalizations.of(context)!.yes,
                        ),
                      ),
                      SizedBox(
                        width: SizeConfig.size10,
                      ),
                      Expanded(
                        child: PositiveCustomBtn(
                          onTap: () {
                            cancelCallback();
                          },
                          title: AppLocalizations.of(context)!.no,
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size15),
              ],
            ),
          ),
        ),
      );
    },
  );
}

showCommonDialog(
    {required BuildContext context,
    required String text, String? header,
    required VoidCallback confirmCallback,
    required VoidCallback cancelCallback,
    required String confirmText,
    required String cancelText}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: Get.width,
                  color: AppColors.primaryColor,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                  child: CustomText(
                      header?? AppLocalizations.of(context)!.confirm,
                    color: Colors.white,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: CustomText(
                    text,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: Row(
                    children: [
                      if (confirmText.isNotEmpty)...[
                        Expanded(
                          child: CustomBtn(
                            bgColor: AppColors.white,
                            borderColor: AppColors.primaryColor,
                            textColor: AppColors.primaryColor,
                            onTap: () {
                              confirmCallback();
                            },
                            title: confirmText,
                          ),
                        ),
                        SizedBox(
                          width: SizeConfig.size10,
                        ),
                      ],


                      Expanded(
                        child: PositiveCustomBtn(
                          onTap: () {
                            cancelCallback();
                          },
                          title: cancelText,
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size15),
              ],
            ),
          ),
        ),
      );
    },
  );
}
