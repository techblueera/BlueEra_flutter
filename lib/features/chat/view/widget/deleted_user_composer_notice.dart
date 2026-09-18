import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Stands in for the composer in a thread whose other participant has deleted
/// their account.
///
/// It replaces the input bar rather than disabling it: a greyed-out text field
/// invites a tap and then says nothing, whereas this states the reason once and
/// leaves the history — which belongs to the person still here — untouched
/// above it.
class DeletedUserComposerNotice extends StatelessWidget {
  const DeletedUserComposerNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size14,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.whiteE5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline,
              size: SizeConfig.size16, color: AppColors.grayText),
          SizedBox(width: SizeConfig.size8),
          Flexible(
            child: CustomText(
              AppStrings.deletedUserCannotMessage.tr,
              color: AppColors.grayText,
              fontSize: SizeConfig.size14,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
