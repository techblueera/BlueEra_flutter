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
      appBar: const CommonBackAppBar(title: "Emergency Contact  ",actionText:"Step: 3/4"),
      body: Padding(
        padding: EdgeInsets.all(SizeConfig.paddingM),
        child: CommonCardWidget(
          child: Column(
            children: [
              CommonTextField(
                title: "Name",
                hintText: "E.g. Jane Doe",
                textEditController: controller.nameController,
              ),
              SizedBox(height: 16),
              CommonTextField(
                title: "Mobile Number",
                hintText: "E.g. +919876543212",
                keyBoardType: TextInputType.phone,
                maxLength: 10,
                textEditController: controller.mobileController,
              ),
              SizedBox(height: 16),
              CommonTextField(
                title: "Relationship",
                hintText: "E.g. Father/Mother/Brother/Sister...",
                textEditController: controller.relationshipController,
              ),
              SizedBox(height: 24),
              Obx(() => CustomBtn(
                    isValidate: controller.isValid.value && !controller.isSaving.value,
                    onTap: controller.isValid.value && !controller.isSaving.value
                        ? controller.submit
                        : null,
                    title: "Next",
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
