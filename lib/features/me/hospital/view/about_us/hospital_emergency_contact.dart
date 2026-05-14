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

  /// Shared rules for both phone fields. The min-length message is parameter-
  /// ized so each field keeps its current copy verbatim (no behavior change).
  /// The controller's `_validate` listener is the source of truth for the
  /// submit-button enable state; this validator only drives in-field errors.
  String? _phoneValidator(String? value, {required String minLengthMessage}) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.startsWith('0')) return 'Leading zeros not allowed';
    if (value.length < 10) return minLengthMessage;
    return null;
  }

  Widget _phoneField({
    required TextEditingController textController,
    required String title,
    required String hint,
    required int maxLength,
    required String minLengthMessage,
  }) {
    return CommonTextField(
      textEditController: textController,
      hintText: hint,
      title: title,
      maxLength: maxLength,
      isValidate: true,
      keyBoardType: TextInputType.number,
      regularExpression: RegularExpressionUtils.digitsPattern,
      validator: (value) =>
          _phoneValidator(value, minLengthMessage: minLengthMessage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.emergencyContact),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final canSubmit = controller.isFormValid && !controller.isSaving.value;
        return CommonCardWidget(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              _phoneField(
                textController: controller.emergencyController,
                title: AppStrings.emergencyNumber,
                hint: "9888767657",
                maxLength: 10,
                minLengthMessage: '10 digits required',
              ),
              const SizedBox(height: 20),
              _phoneField(
                textController: controller.appointmentController,
                title: AppStrings.appointmentNumber,
                hint: "9343767657",
                maxLength: 11,
                minLengthMessage: 'Minimum 10 digits required',
              ),
              const SizedBox(height: 40),
              CustomBtn(
                isValidate: canSubmit,
                onTap: canSubmit ? controller.submit : null,
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
