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

class DrivingLicenceCardWidget extends StatelessWidget {
  DrivingLicenceCardWidget({super.key});

  final controller = Get.find<DeliveryPartnerController>();

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Form(
          key: controller.dlFormKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonTextField(
              textEditController: controller.drivingLicenseController,
              title: AppStrings.drivingLicenceNumber,
              hintText: 'E.g. DL0120110012345',
              keyBoardType: TextInputType.text,
              validator: ValidationMethod.validateDrivingLicense,
              isCapitalize: true,
              maxLength: 16,
              // Show the "n / 16" counter. A licence number is long enough
              // that riders lose their place typing it, and the field silently
              // stops accepting input at the cap — the counter is what makes
              // that visible instead of feeling like a broken keyboard.
              isCounterVisible: true,
            ),
            SizedBox(height: SizeConfig.paddingM),

            // Rebuilt on every keystroke (the field) and on the request state
            // (the controller). The button used to read `.value` from outside
            // an Obx, so its loading state never rebuilt at all.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.drivingLicenseController,
              builder: (context, value, _) {
                final bool isValid =
                    ValidationMethod.validateDrivingLicense(value.text) == null;
                return Obx(() {
                  final loading =
                      controller.isRiderDrivingVerificationLoading.value;
                  // Dead until the number passes the same validator the field
                  // uses: dimmed AND untappable, so an invalid licence can't
                  // reach the API at all. The field auto-validates as you type
                  // (CommonTextField defaults to onUserInteraction), so the
                  // reason is already on screen above the button.
                  final enabled = isValid && !loading;
                  return CustomBtn(
                    title: loading ? null : AppStrings.upload,
                    bgColor: enabled
                        ? AppColors.primaryColor
                        : AppColors.primaryColor.withValues(alpha: 0.5),
                    onTap: enabled
                        ? () =>
                            controller.ridersDrivingLicenceVerificationApi()
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
