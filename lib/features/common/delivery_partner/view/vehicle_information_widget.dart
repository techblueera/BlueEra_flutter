import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/model/vehicle_enums_response.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleInformationWidget extends StatefulWidget {
  VehicleInformationWidget({super.key, required this.screeName});

  final String screeName;

  @override
  State<VehicleInformationWidget> createState() => _VehicleInformationWidgetState();
}

class _VehicleInformationWidgetState extends State<VehicleInformationWidget> {
  final controller = Get.find<DeliveryPartnerController>();

  @override
  initState(){
    super.initState();
    controller.fetchVehicleDataEnum();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: CustomFormCard(
          padding: EdgeInsets.zero,
          child: Form(
            key: controller.formKeyStep6,
            child: Obx(() => controller.isVehicleDataEnumLoading.value ?
            Center(child: CircularProgressIndicator())
                :  AbsorbPointer(
                  absorbing: controller.isRiderVehicleInformationLoading.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Vehicle Type
                      CustomText(
                        AppStrings.vehicleType,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDropdownDialog<VehicleEnumItem>(
                        items: controller.getFilteredVehicles(
                            userProfessionGlobal,
                            controller.vehicleEnumResponse?.vehicleType ?? []
                        ),
                        selectedValue: controller.selectedVehicleType.value,
                        title: AppStrings.vehicleType,
                        hintText: AppStrings.egTwoThreeWheeler,
                        displayValue: (value) => value.slugValue,
                        onChanged: (value) {
                          controller.selectedVehicleType.value = value;
                        },
                        // validator: (value) {
                        //   return null;
                        // },
                      ),
                      SizedBox(height: SizeConfig.paddingM),

                      /// Registration Type
                      CustomText(
                        AppStrings.registrationType,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDropdownDialog<VehicleEnumItem>(
                        items: controller.vehicleEnumResponse?.registrationType ?? [],
                        selectedValue: controller.selectedVehicleRegistrationType.value,
                        title: AppStrings.registrationType,
                        hintText: AppStrings.egPersonalCommercial,
                        displayValue: (value) => value.slugValue,
                        onChanged: (value) {
                          controller.selectedVehicleRegistrationType.value = value;
                        },
                        // validator: (value) {
                        //   return null;
                        // },
                      ),
                      SizedBox(height: SizeConfig.paddingM),

                      /// Vehicle Use Type
                      CustomText(
                        AppStrings.vehicleUseType,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDropdownDialog<VehicleEnumItem>(
                        items: controller.vehicleEnumResponse?.vehicleUsesType ?? [],
                        selectedValue: controller.selectedVehicleUseType.value,
                        title: AppStrings.vehicleUseType,
                        hintText: AppStrings.egPassengerDeliveryGoods,
                        displayValue: (value) => value.slugValue,
                        onChanged: (value) {
                          controller.selectedVehicleUseType.value = value;
                        },
                        // validator: (value) {
                        //   return null;
                        // },
                      ),
                      SizedBox(height: SizeConfig.paddingM),

                      /// Vehicle Name
                      CommonTextField(
                        title: AppStrings.vehicleNameCompanyName.tr,
                        hintText:"Honda",
                        textEditController: controller.vehicleNameController,
                        isValidate: true,
                      ),
                      SizedBox(height: SizeConfig.paddingM),

                      /// Fuel Type
                      CustomText(
                        AppStrings.fuelType,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDropdownDialog<VehicleEnumItem>(
                        items: controller.vehicleEnumResponse?.fuelType ?? [],
                        selectedValue: controller.selectedFuelType.value,
                        title: AppStrings.fuelType,
                        hintText: AppStrings.egPetrolDiesel,
                        displayValue: (value) => value.slugValue,
                        onChanged: (value) {
                          controller.selectedFuelType.value = value;
                        },
                        // validator: (value) {
                        //   return null;
                        // },
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

                      /// Vehicle Model Year (Manufacturing)
                      CustomText(
                        AppStrings.vehicleModelYearManufacturing,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CommonDropdownDialog<String>(
                        items: controller.vehicleModelYears,
                        selectedValue:
                            controller.selectedVehicleModelYear.value,
                        title: AppStrings.vehicleModelYearManufacturing,
                        hintText: AppStrings.eg2020,
                        displayValue: (value) => value,
                        onChanged: (value) {
                          controller.selectedVehicleModelYear.value = value;
                          controller.vehicleModelController.text = value ?? '';
                        },
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
                            :AppStrings.upload,
                        onTap: () =>
                            controller.ridersOnboardingVehicleInformationApi(
                              widget.screeName
                            ),
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
