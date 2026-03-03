import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../emergency/controller/emergency_privacy_alerts_controller.dart';

class EmergencyPrivacyAlertsScreen extends StatefulWidget {
  const EmergencyPrivacyAlertsScreen({super.key});
  @override
  State<EmergencyPrivacyAlertsScreen> createState() => _EmergencyPrivacyAlertsScreenState();
}

class _EmergencyPrivacyAlertsScreenState extends State<EmergencyPrivacyAlertsScreen> {
  late final EmergencyPrivacyAlertsController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => EmergencyPrivacyAlertsController());
  }

  Widget _switchTile(String title, RxBool rx) {
    return Obx(() => ListTile(
          contentPadding: EdgeInsets.zero,
          title: CustomText(title),
          trailing: SizedBox(
            height: 30, // Tighten vertical space
            width: 45, // Tighten horizontal space
            child: Transform.scale(
              scale: 0.75, //
              child: Switch(
                value: rx.value,
                onChanged: (v) => rx.value = v,
                activeColor: AppColors.primaryColor,

              ),
            ),
          ),
        ));
  }

  Widget _checkbox(String title, RxBool rx) {
    return Obx(() => CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: CustomText(title),
          value: rx.value,checkColor: AppColors.white,
          onChanged: (v) => rx.value = v ?? false,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(title: "Privacy & Alert  Step: 3/3"),
      body: Padding(
        padding: EdgeInsets.all(SizeConfig.paddingM),
        child: CommonCardWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _switchTile("Mask My Phone Number", controller.maskPhoneNumber),
              _switchTile("Send SMS Alert with Location", controller.sendSmsAlertWithLocation),
              _switchTile("Share Medical Info During Emergency", controller.shareMedicalInfo),
              _switchTile("Send Chat Alert with GPS", controller.sendChatAlertWithGps),
              SizedBox(height: 16),
              _checkbox("I confirm the above information is accurate.", controller.confirmAccurateInfo),
              _checkbox("I agree to share this information during emergencies.", controller.agreeToShareDuringEmergency),
              SizedBox(height: 24),
              Obx(() => CustomBtn(
                    isValidate: controller.isValid && !controller.isSaving.value,
                    onTap: controller.isValid && !controller.isSaving.value ? controller.submit : null,
                    title: "Submit",
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
