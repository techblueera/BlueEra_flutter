import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

Future<bool> showServiceSwitchConfirmationDialog(BuildContext context) async {
  final appLocalizations = AppLocalizations.of(context);
  return await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.blue2A,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size20, horizontal: SizeConfig.size20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                appLocalizations?.switchBusinessTypeQuestion,
                fontSize: SizeConfig.title,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(
                height: SizeConfig.size15,
              ),
              CustomText(
                appLocalizations?.confirmSwitchBusinessTypeMessage,
                textAlign: TextAlign.center,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w400,
              ),
              SizedBox(
                height: SizeConfig.size20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: CustomText(
                      appLocalizations?.cancel,
                      textAlign: TextAlign.center,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                    ),

                  ),
                  SizedBox(
                    width: SizeConfig.size5,
                  ),
                  Container(
                    height: SizeConfig.size35,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: CustomText(
                          appLocalizations?.confirmSwitchBusinessTypeYes,
                          textAlign: TextAlign.center,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                        )
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    ),
  ) ??
      false; // fallback to false if dialog is dismissed
}
