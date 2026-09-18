import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/account_deletion/model/deletion_blocked_model.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The `409 deletion_blocked` answer from `/account/deletion/init`.
///
/// A dialog and not a snackbar because there can be several blockers at once
/// (wallet balance *and* two live orders *and* a subscription) and each one
/// carries a full sentence — a snackbar truncates all but the first.
///
/// Every line is the backend's own `blockers[].message`: those are written for
/// the user and already say what to do about it, so the app doesn't
/// re-describe them from `type`. The only thing read off `type` is
/// `check_unavailable`, which is a backend dependency being unreachable rather
/// than anything the user did — it gets the neutral grey dot instead of the
/// warning red one, so a "try again in a few minutes" line doesn't look like a
/// debt.
void showDeletionBlockedDialog(DeletionBlockedResponse blocked) {
  final blockers = blocked.blockers;
  Get.dialog(
    Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Get.width,
                color: AppColors.primaryColor,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                child: CustomText(
                  AppStrings.accountDeletionBlockedTitle.tr,
                  color: Colors.white,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        // The app's own line first; the server's headline is
                        // display-ready but not localised.
                        AppStrings.accountDeletionBlockedIntro.tr,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size12),
                      for (final blocker in blockers)
                        Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: _blockerRow(blocker),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomBtn(
                    bgColor: AppColors.white,
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    onTap: () => Get.back(),
                    title: AppStrings.ok.tr,
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size15),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

Widget _blockerRow(DeletionBlocker blocker) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(top: SizeConfig.size6),
        child: Container(
          height: 6,
          width: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: blocker.isTransient ? AppColors.grayText : AppColors.red00,
          ),
        ),
      ),
      SizedBox(width: SizeConfig.size8),
      Expanded(
        child: CustomText(
          blocker.message,
          color: AppColors.mainTextColor,
          maxLines: 5,
        ),
      ),
    ],
  );
}
