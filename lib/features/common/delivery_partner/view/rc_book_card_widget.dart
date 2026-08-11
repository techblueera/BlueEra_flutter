import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RcBookCardWidget extends StatelessWidget {
  RcBookCardWidget({super.key});

  final controller = Get.find<DeliveryPartnerController>();

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Form(
          key: controller.rcFormKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// RC
            CommonTextField(
              textEditController: controller.rcController,
              title: AppStrings.rcNumber,
              titleColor: AppColors.mainTextColor,
              hintText: AppStrings.egUP32AB12,
              keyBoardType: TextInputType.text,
              validator: ValidationMethod.validateRC,
              isCapitalize: true,
              // 13, not 11: the rider types the number the way it is printed
              // on the RC, separators included (`RJ-19-CA-1234`). The 11-char
              // limit is on the NORMALISED value and is enforced by
              // [ValidationMethod.validateRC], which strips the separators
              // first.
              maxLength: ValidationMethod.rcMaxLengthFormatted,
              isCounterVisible: true,
            ),
            SizedBox(height: SizeConfig.paddingM),

            // Rebuilt on every keystroke (the field) and on the request state
            // (the controller). The button used to read `.value` from outside
            // an Obx, so its loading state never rebuilt at all.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.rcController,
              builder: (context, value, _) {
                final bool isValid =
                    ValidationMethod.validateRC(value.text) == null;
                return Obx(() {
                  final loading =
                      controller.isRiderDrivingVerificationLoading.value;
                  // Dead until the number passes the same validator the field
                  // uses: dimmed AND untappable, so an invalid registration
                  // can't reach the API at all.
                  final enabled = isValid && !loading;
                  return CustomBtn(
                    title: loading ? null : AppStrings.upload,
                    bgColor: enabled
                        ? AppColors.primaryColor
                        : AppColors.primaryColor.withValues(alpha: 0.5),
                    onTap: enabled
                        ? () => controller.ridersRcBookVerificationApi()
                        : null,
                    radius: 10.0,
                    isLoading: loading,
                  );
                });
              },
            ),
            // SizedBox(height: SizeConfig.paddingM),
          ],
        )));
  }
}
