import 'package:BlueEra/core/constants/app_strings.dart';
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
                keyBoardType: TextInputType.phone,
                maxLength: 10,
                textEditController: controller.mobileController,
              ),
              SizedBox(height: 16),
              CommonTextField(
                title: AppStrings.emergencyRelationship,
                hintText: AppStrings.emergencyRelationshipHint,
                textEditController: controller.relationshipController,
              ),
              SizedBox(height: 24),
              Obx(() => CustomBtn(
                    isValidate: controller.isValid.value && !controller.isSaving.value,
                    onTap: controller.isValid.value && !controller.isSaving.value
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
