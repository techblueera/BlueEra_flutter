import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef OnChangeString = void Function(String value);

class CommonTextField extends StatelessWidget {
  final TextEditingController? textEditController;
  final String? title;
  final String? initialValue;
  final bool? isValidate;
  final bool isCounterVisible;
  final bool? readOnly;
  final TextInputType? keyBoardType;
  final ValidationTypeEnum? validationType;
  final String? regularExpression;
  final int? inputLength;
  final String? hintText;
  final String? validationMessage;
  final String? preFixIconPath;
  final int? maxLine;
  final int? maxLength;
  final Widget? sIcon;
  final Widget? pIcon;
  final bool? obscureValue;
  final bool? isCapitalize;
  final bool? underLineBorder;
  final bool? showLabel;
  final bool? isVehicleNumberValidate;
  final OnChangeString? onChange;
  final Color? titleColor;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? hintTextColor;
  final double? borderWidth;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enableInteractiveSelection;
  final VoidCallback? onDone; // Add a callback for the Done action

  final FontWeight? hintFontWeight;
  final EdgeInsetsGeometry? contentPadding;
  final String? Function(String?)? validator;
  final FontWeight? fontWeight;
  final double? fontSize;
  final FocusNode? focusNode;
  final TextStyle? hintStyle;
  final bool onTapOutsideTrue;
  final bool includeTapRegion;
  final int? minLines;
  final AutovalidateMode? autovalidateMode;

  // New parameters for clear icon functionality
  final bool showClearIcon;
  final bool isOptionalFiled;
  final VoidCallback? onClearTap;
  final String? prefixText;
  final TextInputAction? textInputAction;


  const CommonTextField({
    super.key,
    this.validator,
    this.regularExpression,
    this.title,
    this.textEditController,
    this.isValidate = true,
    this.isCounterVisible = false,
    this.enableInteractiveSelection = true,
    this.isCapitalize = false,
    this.isOptionalFiled = false,
    this.keyBoardType,
    this.validationType,
    this.inputLength,
    this.readOnly = false,
    this.underLineBorder = false,
    this.showLabel = false,
    this.hintText,
    this.validationMessage,
    this.maxLine,
    this.sIcon,
    this.pIcon,
    this.maxLength,
    this.preFixIconPath,
    this.onChange,
    this.initialValue = '',
    this.obscureValue,
    this.titleColor = AppColors.black,
    this.onTap,
    this.borderColor,
    this.hintTextColor,
    this.borderWidth,
    this.hintFontWeight,
    this.contentPadding,
    this.fontWeight,
    this.fontSize,
    this.hintStyle,
    this.onDone,
    this.focusNode,
    this.onTapOutsideTrue = true,
    this.isVehicleNumberValidate = false,
    this.includeTapRegion = true,
    this.inputFormatters,
    this.minLines,
    this.showClearIcon = false,
    this.onClearTap,
    this.autovalidateMode,
    this.prefixText, this.textInputAction,
  });

  /// PLEASE IMPORT GET X PACKAGE
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title == null || (title?.isEmpty ?? false)
            ? const SizedBox.shrink()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title ?? '',
                    fontSize: fontSize ?? SizeConfig.medium,
                    fontWeight: fontWeight ?? FontWeight.w500,
                    color: titleColor ?? AppColors.black,
                  ),
                  // if (isOptionalFiled) const OptionalTextWidget(),
                ],
              ),
        title == null || (title?.isEmpty ?? false)
            ? const SizedBox.shrink()
            : SizedBox(height: SizeConfig.paddingXSL),
        Container(
          width: SizeConfig.screenWidth,
          decoration: BoxDecoration(
            color: AppColors.white, // White background
            boxShadow: [AppShadows.textFieldShadow],
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias, // ✅ Allow toolbar to overflow

          child: TextFormField(
            autovalidateMode:
                autovalidateMode ?? AutovalidateMode.onUserInteraction,
            style: TextStyle(color: Colors.black, fontSize: SizeConfig.large),
            controller: textEditController,
            maxLength: maxLength ?? AppConstants.inputCharterLimit,
            onTap: onTap,

            keyboardType: keyBoardType ?? TextInputType.text,
            maxLines: maxLine ?? 1,
            enableInteractiveSelection: true,

            textCapitalization: (isCapitalize ?? false)
                ? TextCapitalization.characters
                : TextCapitalization.sentences,
            inputFormatters: inputFormatters ??
                [
                  LengthLimitingTextInputFormatter(inputLength),
                  if (regularExpression?.isNotEmpty == true)
                    FilteringTextInputFormatter.allow(
                        RegExp(regularExpression!)),
                  NoLeadingSpaceFormatter(),
                  NoConsecutiveSpacesFormatter(),
                ],
            obscureText: validationType == ValidationTypeEnum.password
                ? (obscureValue ?? false)
                : false,
            onChanged: onChange,
            onFieldSubmitted: (value) {
              if (onDone != null) onDone!(); // Trigger Done action
            },
            enabled: !(readOnly ?? false),
            readOnly: readOnly ?? false,
            minLines: minLines,
            validator: validator ??
                (value) {
                  if (isValidate == false) {
                    return null;
                  }
                  if (value == null || value.isEmpty) {
                    return validationMessage ?? AppStrings.required;
                  }
                  if (validationType == ValidationTypeEnum.email) {
                    return ValidationMethod.validateEmail(value);
                  } else if (validationType == ValidationTypeEnum.pNumber) {
                    return ValidationMethod.validatePhone(value);
                  }else if (validationType == ValidationTypeEnum.lNumber) {
                    return ValidationMethod.validateLandline(value);
                  }
                  else if (validationType == ValidationTypeEnum.Url) {
                    return ValidationMethod.urlValidation(value);
                  }else if (validationType == ValidationTypeEnum.username) {
                    return ValidationMethod.userNameValidation(value);
                  }
                  return null;
                },
            // textInputAction: textInputAction ??
            //     (maxLine != null && (maxLine??1) > 1
            //         ? TextInputAction.newline // 👈 allows Enter to go to next line
            //         : TextInputAction.done),
            // textInputAction:textInputAction??TextInputAction.done,
                // maxLine == 4 ? TextInputAction.done : TextInputAction.none,
            focusNode: focusNode,
            decoration: InputDecoration(
              prefixText: prefixText??"",
              contentPadding: contentPadding ??
                  EdgeInsets.symmetric(
                      horizontal: SizeConfig.paddingM,
                      vertical: SizeConfig.paddingXSL),
              hintText: hintText,
              prefixIcon: pIcon,
              // counterText: '',
              suffixIcon: showClearIcon
                  ? InkWell(
                      onTap: onClearTap,
                      child: Icon(
                        CupertinoIcons.clear,
                        color: AppColors.black,
                        size: SizeConfig.paddingM,
                      ),
                    )
                  : sIcon,
              hintStyle: hintStyle ?? theme.inputDecorationTheme.hintStyle,
              errorMaxLines: 2,
            ),
            onTapOutside: (event) => onTapOutsideTrue
                ? FocusScope.of(context).requestFocus(FocusNode())
                : null,
            buildCounter: (context,
                {required currentLength,
                required isFocused,
                required maxLength}) {
              // return null;
              if (!isCounterVisible) return null;
              return CustomText(
                '$currentLength / $maxLength',
                color: AppColors.greyBf,
                fontSize: 12,
              );
            },
          ),
        ),
        // if (isCounterVisible)
        //   Align(
        //     alignment: Alignment.centerRight,
        //     child: Padding(
        //       padding:  EdgeInsets.only(top: SizeConfig.size10),
        //       child: CustomText(
        //         '${textEditController?.text.length} / $maxLength',
        //         color: AppColors.greyBf,
        //         fontSize: 12,
        //       ),
        //     ),
        //   )
      ],
    );
  }
}
