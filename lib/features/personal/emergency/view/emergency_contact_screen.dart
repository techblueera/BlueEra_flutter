import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../emergency/controller/emergency_contacts_controller.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});
  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  late final EmergencyContactsController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => EmergencyContactsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.emergencyContactTitle,
        actionText: AppStrings.emergencyStep3Of4,
      ),
      body: Padding(
        padding: EdgeInsets.all(SizeConfig.paddingM),
        child: CommonCardWidget(
          child: Column(
            children: [
              CommonTextField(
                title: AppStrings.emergencyContactName,
                hintText: AppStrings.emergencyContactNameHint,
                textEditController: controller.nameController,
              ),
              SizedBox(height: 16),
              CommonTextField(
                title: AppStrings.emergencyMobileNumber,
                hintText: AppStrings.emergencyContactMobileHint,
                keyBoardType: TextInputType.number,
                regularExpression: RegularExpressionUtils.digitsPattern,
                maxLength: 10,
                isValidate: true,
                textEditController: controller.mobileController,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.startsWith('0')) return 'Leading zeros not allowed';
                  if (value.length < 10) return 'Minimum 10 digits required';
                  if (RegExp(r'^0+$').hasMatch(value))
                    return 'All zeros not allowed';
                  if (!RegExp(r'^[6-9]').hasMatch(value))
                    return 'Enter a valid mobile number';
                  return null;
                },
                onChange: (_) => controller.update(),
              ),
              SizedBox(height: 16),
              CommonTextField(
                title: AppStrings.emergencyRelationship,
                hintText: AppStrings.emergencyRelationshipHint,
                textEditController: controller.relationshipController,
              ),
              SizedBox(height: 24),
              Obx(() => CustomBtn(
                    isValidate:
                        controller.isValid.value && !controller.isSaving.value,
                    onTap:
                        controller.isValid.value && !controller.isSaving.value
                            ? controller.submit
                            : null,
                    title: AppStrings.next,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
