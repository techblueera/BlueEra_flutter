import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ContactInputField extends StatefulWidget {
  final TextEditingController mobileController;
  final TextEditingController landlineCodeController;
  final TextEditingController landlineNumberController;
  final ContactType selectedType;
  final Function(ContactType) onTypeChanged;
  final Function(String) prefixOnChange;
  final Function(String) mobileNumberOnChange;
  VoidCallback? updateSubmitButtonState;

  ContactInputField({
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
  State<ContactInputField> createState() => _ContactInputFieldState();
}

class _ContactInputFieldState extends State<ContactInputField> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  widget.onTypeChanged(ContactType.Mobile);
                },
                child: Row(

                  children: [
                    SizedBox(
                      height:SizeConfig.size30 ,
                      width: SizeConfig.size30,
                      child: Radio<ContactType>(
                        activeColor: AppColors.primaryColor,
                        value: ContactType.Mobile,
                        groupValue: widget.selectedType,
                        onChanged: (value) {
                          widget.onTypeChanged(value!);
                        },
                      ),
                    ),
                    CustomText(
                      appLocalizations.officeMobNo,
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
                      height:SizeConfig.size30 ,
                      width: SizeConfig.size30,
                      child: Radio<ContactType>(
                        activeColor: AppColors.primaryColor,
                        value: ContactType.Landline,
                        groupValue: widget.selectedType,
                        onChanged: (value) {
                          widget.onTypeChanged(value!);
                        },
                      ),
                    ),
                    CustomText(
                      appLocalizations.officeLandline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height:SizeConfig.size10 ,),
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
    final appLocalizations = AppLocalizations.of(context);

    return CommonTextField(
      textEditController: controller,
      inputLength: 10,
      maxLength: 10,
      keyBoardType: TextInputType.number,
      regularExpression: RegularExpressionUtils.digitsPattern,
      validationType: ValidationTypeEnum.pNumber,
      // title: appLocalizations?.mobileNumber,
      hintText: appLocalizations?.enterMobileNo,
      isValidate: true,

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
    final appLocalizations = AppLocalizations.of(context)!;

    return Container(
      // padding: EdgeInsets.only(top: 5.h),
      // decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      // height: screenHeight(context) * 0.11,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CommonTextField(
              textEditController: codeController,
              inputLength: 5,
              keyBoardType: TextInputType.number,
              regularExpression: RegularExpressionUtils.digitsPattern,
              // validationType: ValidationTypeEnum.pNumber,
              hintText: appLocalizations.prefix,
              isValidate: true,
              onChange: (value) {
                final cursorPosition = codeController.selection;
                codeController.text = value;
                codeController.selection = cursorPosition;
                updateSubmitButtonState();
                prefixOnChange(value);
              },
            ),
          ),
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
              // title: appLocalizations?.mobileNumber,
              hintText: 'Enter LandLine Number',
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
