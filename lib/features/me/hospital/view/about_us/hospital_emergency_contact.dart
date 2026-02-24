import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_emergency_contact_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalEmergencyContactScreen extends StatefulWidget {
  const HospitalEmergencyContactScreen({super.key});

  @override
  State<HospitalEmergencyContactScreen> createState() =>
      _HospitalEmergencyContactScreenState();
}

class _HospitalEmergencyContactScreenState extends State<HospitalEmergencyContactScreen> {
  late final HospitalEmergencyContactController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalEmergencyContactController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Emergency Contact Details",
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return CommonCardWidget(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              CommonTextField(
                textEditController: controller.emergencyController,
                hintText: "9888767657",
                title: "Emergency Number",
                maxLength: 11,
                keyBoardType: TextInputType.phone,
                onChange: (_) {},
              ),
              SizedBox(height: 20),
              CommonTextField(
                textEditController: controller.appointmentController,
                hintText: "9343767657",
                title: "Appointment Number",
                maxLength: 11,
                keyBoardType: TextInputType.phone,
                onChange: (_) {},
              ),
              SizedBox(height: 40),
              CustomBtn(
                isValidate: controller.isFormValid && !controller.isSaving.value,
                onTap: controller.isFormValid && !controller.isSaving.value
                    ? controller.submit
                    : null,
                title: "Submit",
              ),
              SizedBox(height: SizeConfig.size14),
            ],
          ),
        );
      }),
    );
  }
}
