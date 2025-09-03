import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/languages_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

void showConfirmDeleteDialog(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
              alignment: Alignment.center,
              child: CustomText(
                AppLocalizations.of(context)!.confirm,
                color: Colors.white,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText("Are you sure you want to delete?"),
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
                      onTap: onConfirm,
                      title: AppLocalizations.of(context)!.yes,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: CustomBtn(
                      bgColor: AppColors.primaryColor,
                      borderColor: AppColors.primaryColor,
                      textColor: Colors.white,
                      onTap: () => Navigator.of(context).pop(),
                      title: AppLocalizations.of(context)!.no,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size15),
          ],
        ),
      );
    },
  );
}

void showConfirmDialog(
  BuildContext context,
  VoidCallback onConfirm, {
  String? title,
  String? content,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
              alignment: Alignment.center,
              child: CustomText(
                title ?? 'Confirm',
                color: Colors.white,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
              child: CustomText(content ?? 'Are you sure you want to delete?'),
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
                      onTap: onConfirm,
                      title: AppLocalizations.of(context)!.yes,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: CustomBtn(
                      bgColor: AppColors.primaryColor,
                      borderColor: AppColors.primaryColor,
                      textColor: Colors.white,
                      onTap: () => Navigator.of(context).pop(),
                      title: AppLocalizations.of(context)!.no,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size15),
          ],
        ),
      );
    },
  );
}

void showConfirmDialogForLanguageDeletion(BuildContext context,
    LanguageType language, LanguagesController controller, String category) {
  showConfirmDialog(
    context,
    () {
      controller.removeLanguageByCategory(language, category);
      Navigator.of(context).pop();
    },
    title: 'Confirm delete',
    content:
        'Are you sure you want to remove "${language.label}" from this category?',
  );
}


Future<bool> showBooleanConfirmDialog(
  BuildContext context, {
  String? title,
  String? content,
}) async {
  bool confirmed = false;

  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
              alignment: Alignment.center,
              child: CustomText(
                title ?? 'Confirm',
                color: Colors.white,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
              child: CustomText(content ?? 'Are you sure you want to delete?'),
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
                        confirmed = true;
                        Navigator.of(context).pop();
                      },
                      title: AppLocalizations.of(context)!.yes,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: CustomBtn(
                      bgColor: AppColors.primaryColor,
                      borderColor: AppColors.primaryColor,
                      textColor: Colors.white,
                      onTap: () {
                        confirmed = false;
                        Navigator.of(context).pop();
                      },
                      title: AppLocalizations.of(context)!.no,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size15),
          ],
        ),
      );
    },
  );

  return confirmed;
}

