import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleInformationWidget extends StatelessWidget {
  VehicleInformationWidget({super.key});

  final controller = Get.find<DeliveryPartnerController>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: CustomFormCard(
          padding: EdgeInsets.zero,
          child: Form(
            key: controller.formKeyStep6,
            child: Obx(() => AbsorbPointer(
                  absorbing: controller.isRiderVehicleInformationLoading.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Registration Type
                      CustomText(
                        AppStrings.registrationType,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDropdown<VehicleRegistrationType>(
                        items: VehicleRegistrationType.values,
                        selectedValue:
                            controller.selectedVehicleRegistrationType.value,
                        hintText: AppStrings.egPersonalCommercial,
                        displayValue: (value) => value.displayName,
                        onChanged: (value) {
                          controller.selectedVehicleRegistrationType.value =
                              value;
                        },
                        validator: (value) {
                          return null;
                        },
                      ),
                      SizedBox(height: SizeConfig.paddingM),

                      /// Vehicle Type
                      CustomText(
                        AppStrings.vehicleType,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDropdown<VehicleType>(
                        items: VehicleType.values,
                        selectedValue: controller.selectedVehicleType.value,
                        hintText: AppStrings.egTwoThreeWheeler,
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
                        title: AppStrings.vehicleName,
                        hintText: AppStrings.egSP125,
                        textEditController: controller.vehicleNameController,
                        isValidate: true,
                      ),
                      SizedBox(height: SizeConfig.paddingM),

                      /// Fuel Type
                      CustomText(
                        AppStrings.fuelType,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDropdown<FuelType>(
                        items: FuelType.values,
                        selectedValue: controller.selectedFuelType.value,
                        hintText: AppStrings.egPetrolDiesel,
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
                        title: AppStrings.vehicleNumber,
                        hintText: AppStrings.egWB5454,
                        textEditController:
                            controller.vehicleRegistrationNumberController,
                        validator: ValidationMethod.validateVehicleNumber,
                        isCapitalize: true,
                        maxLength: 10,
                      ),
                      SizedBox(height: SizeConfig.paddingM),

                      /// Vehicle Model
                      CommonTextField(
                        title: AppStrings.vehicleModelYearManufacturing,
                        hintText: AppStrings.eg2020,
                        // hintText: "E.g. Honda, Maruti, BMW....",
                        keyBoardType: TextInputType.number,
                        textEditController: controller.vehicleModelController,
                        isValidate: true,
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
                                  onTap: () =>
                                      controller.isTermsAccepted.value =
                                          !controller.isTermsAccepted.value,
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
                                      color: controller.isTermsAccepted.value
                                          ? AppColors.primaryColor
                                          : Colors.transparent,
                                    ),
                                    child: controller.isTermsAccepted.value
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 16)
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
                                    TextSpan(text: AppStrings.acceptAll.tr),
                                    TextSpan(
                                      text: AppStrings.termsConditions.tr,
                                      style: const TextStyle(
                                          color: AppColors.primaryColor),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Get.to(() => CommonWebView(
                                                urlLink: tncLink,
                                                urlTitle:
                                                    AppStrings.termsConditions,
                                              ));
                                        },
                                    ),
                                    TextSpan(text: ' ${AppStrings.and.tr}\n'),
                                    TextSpan(
                                      text: AppStrings.privacyPolicy.tr,
                                      style: const TextStyle(
                                          color: AppColors.primaryColor),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Get.to(() => CommonWebView(
                                                urlLink: privacyLink,
                                                urlTitle:
                                                    AppStrings.privacyPolicy,
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
                        title: controller.isRiderVehicleInformationLoading.value
                            ? null
                            : "Upload",
                        onTap: () =>
                            controller.ridersOnboardingVehicleInformationApi(),
                        radius: 10.0,
                        bgColor: AppColors.primaryColor,
                        isLoading:
                            controller.isRiderVehicleInformationLoading.value,
                      ),
                      SizedBox(height: SizeConfig.size50),
                    ],
                  ),
                )),
          ),
        ),
      ),
    );
  }
}
