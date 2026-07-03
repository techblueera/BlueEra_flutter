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

class PanCardWidget extends StatelessWidget {
  PanCardWidget({super.key});

  final controller = Get.find<DeliveryPartnerController>();

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Form(
          key: controller.panFormKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Pan Number
            CommonTextField(
              textEditController: controller.panNumberController,
              title: AppStrings.panNumber,
              hintText:'E.g. ABCDE1234F',

              keyBoardType: TextInputType.text,
              validator: ValidationMethod.validatePAN,
              isCapitalize: true,
              maxLength: 10,
            ),
            SizedBox(height: SizeConfig.paddingM),

            CustomBtn(
              title: controller.isRiderPersonalIdentificationLoading.value
                  ? null
                  : AppStrings.upload,
              onTap: () => controller.ridersPanCardApi(),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              isLoading: controller.isRiderPersonalIdentificationLoading.value,
            ),
          ],
        )));
  }
}
