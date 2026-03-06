import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../emergency/controller/emergency_basic_info_controller.dart';

class EmergencyBasicInfoScreen extends StatefulWidget {
  const EmergencyBasicInfoScreen({super.key});
  @override
  State<EmergencyBasicInfoScreen> createState() => _EmergencyBasicInfoScreenState();
}

class _EmergencyBasicInfoScreenState extends State<EmergencyBasicInfoScreen> {
  late final EmergencyBasicInfoController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => EmergencyBasicInfoController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(title: "Basic Info"),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: CommonCardWidget(
            child: Column(
              children: [
                CommonTextField(
                  title: "Full Name",
                  hintText: "E.g. Rakesh Gupta",
                  textEditController: controller.fullNameController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: "Mobile Number",
                  hintText: "E.g. +919876543210",
                  keyBoardType: TextInputType.phone,
                  maxLength: 10,

                  textEditController: controller.mobileController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: "Alternate Number",
                  hintText: "E.g. +919876543211",
                  keyBoardType: TextInputType.phone,
                  maxLength: 10,
                  textEditController: controller.alternateController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: "Email ID (Optional)",
                  hintText: "E.g. rakeshgupta05@gmail.com",
                  keyBoardType: TextInputType.emailAddress,
                  textEditController: controller.emailController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: "Vehicle Number",
                  hintText: "E.g. KA01AB1234",
                  textEditController: controller.vehicleController,
                ),
                SizedBox(height: 16),

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
      ),
    );
  }
}
