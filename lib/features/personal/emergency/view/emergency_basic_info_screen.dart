import 'package:BlueEra/core/constants/app_strings.dart';
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
      appBar: CommonBackAppBar(title: AppStrings.basicInfo),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: CommonCardWidget(
            child: Column(
              children: [
                CommonTextField(
                  title: AppStrings.fullName,
                  hintText: AppStrings.emergencyFullNameHint,
                  textEditController: controller.fullNameController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: AppStrings.emergencyMobileNumber,
                  hintText: AppStrings.emergencyMobileHint,
                  keyBoardType: TextInputType.phone,
                  maxLength: 10,

                  textEditController: controller.mobileController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: AppStrings.emergencyAlternateNumber,
                  hintText: AppStrings.emergencyAlternateHint,
                  keyBoardType: TextInputType.phone,
                  maxLength: 10,
                  textEditController: controller.alternateController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: AppStrings.emergencyEmailOptional,
                  hintText: AppStrings.emergencyEmailHint,
                  keyBoardType: TextInputType.emailAddress,
                  textEditController: controller.emailController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: AppStrings.vehicleNumber,
                  hintText: AppStrings.emergencyVehicleHint,
                  textEditController: controller.vehicleController,
                ),
                SizedBox(height: 16),

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
      ),
    );
  }
}
