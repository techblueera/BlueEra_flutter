import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/deliver_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleInformationRidingScreen extends StatefulWidget {
  const VehicleInformationRidingScreen({super.key});

  @override
  State<VehicleInformationRidingScreen> createState() => _VehicleInformationRidingScreenState();
}

class _VehicleInformationRidingScreenState extends State<VehicleInformationRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Vehicle Information  ",
        // onBackTap: onBackPressed,
        buildCustomWidget: ()=> Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              "Step-6/6",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: CustomFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Registration Type
              CustomText(
                "Registration Type",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              CommonDropdown<VehicleRegistrationType>(
                items: VehicleRegistrationType.values,
                selectedValue: controller.selectedVehicleRegistrationType.value,
                hintText: "E.g. Personal, Commercial....",
                displayValue: (value) => value.displayName,
                onChanged: (value) {
                  controller.selectedVehicleRegistrationType.value = value;
                },
                validator: (value) {
                  return null;
                },
              ),
              SizedBox(height: SizeConfig.paddingM),

              /// Vehicle Type
              CustomText(
                "Vehicle Type",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              CommonDropdown<VehicleType>(
                items: VehicleType.values,
                selectedValue: controller.selectedVehicleType.value,
                hintText: "E.g. 'Two Wheeler', Three Wheeler....",
                displayValue: (value) => value.displayName,
                onChanged: (value) {
                  controller.selectedVehicleType.value = value;
                },
                validator: (value) {
                  return null;
                },
              ),
              SizedBox(height: SizeConfig.paddingM),

              /// Vehicle Name
              CommonTextField(
                title: "Vehicle Name",
                hintText: "E.g. SP125....",
                textEditController: controller.vehicleNameController,
              ),
              SizedBox(height: SizeConfig.paddingM),

              /// Fuel Type
              CustomText(
                "Fuel Type",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              CommonDropdown<FuelType>(
                items: FuelType.values,
                selectedValue: controller.selectedFuelType.value,
                hintText: "Select Gender",
                displayValue: (value) => value.displayName,
                onChanged: (value) {
                  controller.selectedFuelType.value = value;
                },
                validator: (value) {
                  return null;
                },
              ),
              SizedBox(height: SizeConfig.paddingM),

              /// Vehicle Number
              CommonTextField(
                title: "Vehicle Number",
                hintText: "E.g. Wb5454....",
                textEditController: controller.vehicleNumnberController,
              ),
              SizedBox(height: SizeConfig.paddingM),

              /// Vehicle Model
              CommonTextField(
                title: "Vehicle Model (Year of Manufacturing)",
                hintText: "E.g. Honda, Maruti, BMW....",
                textEditController: controller.vehicleModelController,
              ),
              SizedBox(height: SizeConfig.paddingM),

              /// terms & conditions
              SizedBox(
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ///  Checkbox with custom blue border
                    Obx(() => GestureDetector(
                      onTap: () => controller.isTermsAccepted.value = !controller.isTermsAccepted.value,
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primaryColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: controller.isTermsAccepted.value ? AppColors.primaryColor : Colors.transparent,
                        ),
                        child: controller.isTermsAccepted.value
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    )),
                    SizedBox(width: SizeConfig.size8),

                    /// ✅ Terms & Privacy Rich Text
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontFamily: AppConstants.OpenSans,
                          ),
                          children: [
                            const TextSpan(text: 'Accept All '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(color: AppColors.primaryColor),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.to(() => CommonWebView(
                                    urlLink: tncLink,
                                    urlTitle: 'Terms & Conditions',
                                  ));
                                },
                            ),
                            const TextSpan(text: ' and\n'),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(color: AppColors.primaryColor),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.to(() => CommonWebView(
                                    urlLink: privacyLink,
                                    urlTitle: 'Privacy Policy',
                                  ));
                                },
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.paddingL),
              CustomBtn(
                title: 'Post Now',
                onTap: (){},
                radius: 10.0,
                bgColor: AppColors.primaryColor,
              ),

            ],
          ),
        ),
      ),
    );
  }
}
