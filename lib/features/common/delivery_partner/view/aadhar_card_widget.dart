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

class AadharCardWidget extends StatelessWidget {
  AadharCardWidget({super.key});

  final controller = Get.find<DeliveryPartnerController>();

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Form(
          key: controller.aadharFormKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Aadhar
            CommonTextField(
              textEditController: controller.aadharController,
              title: AppStrings.aadharNumber,
              hintText: 'E.g. 5678 1234 6679 9012',
              keyBoardType: TextInputType.number,
              validator: ValidationMethod.validateAadhaar,
              maxLength: 12,
            ),
            SizedBox(height: SizeConfig.paddingM),

            CustomBtn(
              title: controller.isRiderPersonalIdentificationLoading.value
                  ? null
                  :AppStrings.upload,
              onTap: () =>
                  controller.ridersAadharCardApi(),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              isLoading: controller.isRiderPersonalIdentificationLoading.value,
            ),
            // SizedBox(height: SizeConfig.paddingM),
          ],
        )));
  }
}
