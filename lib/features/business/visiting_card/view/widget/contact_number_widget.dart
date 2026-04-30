import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class ContactInputField1 extends StatefulWidget {
  final TextEditingController mobileController;
  final TextEditingController landlineCodeController;
  final TextEditingController landlineNumberController;
  final ContactType selectedType;
  final Function(ContactType) onTypeChanged;
  final Function(String) prefixOnChange;
  final Function(String) mobileNumberOnChange;
  VoidCallback? updateSubmitButtonState;

  ContactInputField1({
    super.key,
    required this.mobileController,
    required this.landlineCodeController,
    required this.landlineNumberController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.mobileNumberOnChange,
    required this.prefixOnChange,
    this.updateSubmitButtonState,
  });

  @override
  State<ContactInputField1> createState() => _ContactInputFieldState();
}

class _ContactInputFieldState extends State<ContactInputField1> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioGroup<ContactType>(
          groupValue: widget.selectedType,
          onChanged: (value) {
            if (value != null) widget.onTypeChanged(value);
          },
          child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  widget.onTypeChanged(ContactType.Mobile);
                },
                child: Row(
                  children: [
                    SizedBox(
                      height: SizeConfig.size30,
                      width: SizeConfig.size30,
                      child: Radio<ContactType>(
                        activeColor: AppColors.primaryColor,
                        value: ContactType.Mobile,
                        // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        // visualDensity: VisualDensity(horizontal: -3, vertical: -3),
                      ),
                    ),
                    Flexible(
                      child: CustomText(
                        AppStrings.officeMobNo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  widget.onTypeChanged(ContactType.Landline);
                },
                child: Row(
                  children: [
                    SizedBox(
                      height: SizeConfig.size30,
                      width: SizeConfig.size30,
                      child: Radio<ContactType>(
                        activeColor: AppColors.primaryColor,
                        value: ContactType.Landline,
                        // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        // visualDensity: VisualDensity(horizontal: -3, vertical: -3),
                      ),
                    ),
                    Flexible(
                      child: CustomText(
                        AppStrings.officeLandline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
        SizedBox(
          height: SizeConfig.size10,
        ),
        widget.selectedType == ContactType.Mobile
            ? _MobileField(
                controller: widget.mobileController,
                updateSubmitButtonState: () {
                  widget.updateSubmitButtonState;
                },
                mobileNumberOnChange: widget.mobileNumberOnChange,
              )
            : _LandlineField(
                codeController: widget.landlineCodeController,
                numberController: widget.landlineNumberController,
                updateSubmitButtonState: () {
                  widget.updateSubmitButtonState;
                },
                mobileNumberOnChange: widget.mobileNumberOnChange,
                prefixOnChange: widget.prefixOnChange,
              ),
      ],
    );
  }
}

class _MobileField extends StatelessWidget {
  final TextEditingController controller;

  final VoidCallback updateSubmitButtonState;
  final Function(String) mobileNumberOnChange;

  const _MobileField({
    required this.controller,
    required this.updateSubmitButtonState,
    required this.mobileNumberOnChange,
  });

  @override
  Widget build(BuildContext context) {
    return CommonTextField(
      textEditController: controller,
      inputLength: 10,
      maxLength: 10,
      keyBoardType: TextInputType.number,
      regularExpression: RegularExpressionUtils.digitsPattern,
      validationType: ValidationTypeEnum.pNumber,
      hintText: AppStrings.enterMobileNumberHint.tr,
      isValidate: true,
      autoFillType: AutoFillType.phone,
      onChange: (value) {
        final cursorPosition = controller.selection;
        controller.text = value;
        controller.selection = cursorPosition;
        updateSubmitButtonState();
        mobileNumberOnChange(value);
      },
    );
  }
}

class _LandlineField extends StatelessWidget {
  final TextEditingController codeController;
  final TextEditingController numberController;
  final Function(String) prefixOnChange;
  final Function(String) mobileNumberOnChange;
  final VoidCallback updateSubmitButtonState;

  const _LandlineField({
    required this.codeController,
    required this.numberController,
    required this.updateSubmitButtonState,
    required this.mobileNumberOnChange,
    required this.prefixOnChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: EdgeInsets.only(top: 5.h),
      // decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      // height: screenHeight(context) * 0.11,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: SizeConfig.size10,
          ),
          Expanded(
            flex: 3,
            child: CommonTextField(
              textEditController: numberController,
              inputLength: 8,
              maxLength: 8,
              keyBoardType: TextInputType.number,
              regularExpression: RegularExpressionUtils.digitsPattern,
              validationType: ValidationTypeEnum.lNumber,
              hintText: AppStrings.officeLandline.tr,
              isValidate: true,
              onChange: (value) {
                final cursorPosition = numberController.selection;
                numberController.text = value;
                numberController.selection = cursorPosition;
                updateSubmitButtonState();
                mobileNumberOnChange(value);
              },
            ),
          )
        ],
      ),
    );
  }
}
