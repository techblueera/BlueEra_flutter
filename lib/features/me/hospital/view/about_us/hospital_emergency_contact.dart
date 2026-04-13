import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
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

class _HospitalEmergencyContactScreenState
    extends State<HospitalEmergencyContactScreen> {
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
        title: AppStrings.emergencyContact,
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
                title: AppStrings.emergencyNumber,
                maxLength: 10,
                isValidate: true,
                keyBoardType: TextInputType.number,
                regularExpression: RegularExpressionUtils.digitsPattern,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.startsWith('0')) return 'Leading zeros not allowed';
                  if (value.length < 10) return '10 digits required';
                  if (RegExp(r'^0+$').hasMatch(value))
                    return 'All zeros not allowed';
                  return null;
                },
                onChange: (_) => controller
                    .update(), // Refresh to update button state if needed
              ),
              SizedBox(height: 20),
              CommonTextField(
                textEditController: controller.appointmentController,
                hintText: "9343767657",
                title: AppStrings.appointmentNumber,
                maxLength: 11,
                isValidate: true,
                keyBoardType: TextInputType.number,
                regularExpression: RegularExpressionUtils.digitsPattern,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.startsWith('0')) return 'Leading zeros not allowed';
                  if (value.length < 10) return 'Minimum 10 digits required';
                  if (RegExp(r'^0+$').hasMatch(value))
                    return 'All zeros not allowed';
                  return null;
                },
                onChange: (_) => controller.update(),
              ),
              SizedBox(height: 40),
              CustomBtn(
                isValidate:
                    controller.isFormValid && !controller.isSaving.value,
                onTap: controller.isFormValid && !controller.isSaving.value
                    ? controller.submit
                    : null,
                title: AppStrings.submit,
              ),
              SizedBox(height: SizeConfig.size14),
            ],
          ),
        );
      }),
    );
  }
}
