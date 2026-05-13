import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';


void openOwnerEditSheet({
  required BuildContext context,
  required TextEditingController nameController,
  required TextEditingController roleController,
  required TextEditingController emailController,
  required VoidCallback onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // important
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    builder: (context) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        // close keyboard on tap outside
        child: Padding(
          // this ensures the bottom sheet moves *above* the keyboard

          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    CustomText(
                      AppStrings.ownerDetails,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    CloseButton(),
                  ],
                ),
                const SizedBox(height: 20),
                CommonTextField(
                  textEditController: nameController,
                  inputLength: 50,
                  keyBoardType: TextInputType.text,
                  regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                  title: AppStrings.yourName,
                  hintText: AppStrings.yourNameHint,
                  isValidate: false,
                  autoFillType: AutoFillType.name,
                ),
                const SizedBox(height: 16),
                CommonTextField(
                  textEditController: roleController,
                  inputLength: 50,
                  keyBoardType: TextInputType.text,
                  regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                  title: AppStrings.yourRole,
                  hintText: AppStrings.yourRoleHint,
                  isValidate: false,
                ),
                const SizedBox(height: 16),
                CommonTextField(
                  textEditController: emailController,
                  inputLength: 50,
                  keyBoardType: TextInputType.emailAddress,
                  regularExpression: RegularExpressionUtils.emailPattern,
                  title: AppStrings.email,
                  hintText: AppStrings.emailHint,
                  isValidate: false,
                  autoFillType: AutoFillType.email,
                ),
                const SizedBox(height: 24),
                CustomBtn(
                  radius: 10,
                  bgColor: AppColors.primaryColor,
                  title: AppStrings.save,
                  onTap: onSave,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}



Widget buildInfo(String title, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomText(
        title + ":",
        fontSize: SizeConfig.size12,
        color: AppColors.grayText,
        fontWeight: FontWeight.w400,
      ),
      SizedBox(width: SizeConfig.size6),
      Flexible(
        child: CustomText(
          value,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor,
        ),
      ),
    ],
  );
}
