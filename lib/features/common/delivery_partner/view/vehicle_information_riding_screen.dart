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
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleInformationRidingScreen extends StatefulWidget {
  const VehicleInformationRidingScreen({super.key, required this.screeName});

  final String screeName;

  @override
  State<VehicleInformationRidingScreen> createState() => _VehicleInformationRidingScreenState();
}

class _VehicleInformationRidingScreenState extends State<VehicleInformationRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());

  @override
  initState(){
    super.initState();
    controller.fetchVehicleDataEnum();
  }

  @override
  Widget build(BuildContext context) {
    final isFromTab = widget.screeName == "from_tab_view";
    final content = Obx(() => controller.isVehicleDataEnumLoading.value
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        : Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: CustomFormCard(
            child: Form(
              key: controller.formKeyStep6,
              child: AbsorbPointer(
                absorbing: controller.isRiderVehicleInformationLoading.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Vehicle Type
                    CustomText(
                      AppStrings.vehicleType.tr,
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
                      title: AppStrings.vehicleType.tr,
                      selectedValue: controller.selectedVehicleType.value,
                      hintText: AppStrings.egTwoThreeWheeler.tr,
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
                      AppStrings.registrationType.tr,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdownDialog<VehicleEnumItem>(
                      items: controller.vehicleEnumResponse?.registrationType ?? [],
                      selectedValue: controller.selectedVehicleRegistrationType.value,
                      title: AppStrings.registrationType.tr,
                      hintText: AppStrings.egPersonalCommercial.tr,
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
                      AppStrings.vehicleUseType.tr,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdownDialog<VehicleEnumItem>(
                      items: controller.vehicleEnumResponse?.vehicleUsesType ?? [],
                      selectedValue: controller.selectedVehicleUseType.value,
                      title: AppStrings.vehicleUseType.tr,
                      hintText: AppStrings.egPassengerDeliveryGoods.tr,
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
                      title: "Vehicle Name (Company Name)",
                      // title: AppStrings.vehicleName.tr,
                      hintText:"Honda",
                      textEditController: controller.vehicleNameController,
                      isValidate: true,
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    /// Fuel Type
                    CustomText(
                      AppStrings.fuelType.tr,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdownDialog<VehicleEnumItem>(
                      items: controller.vehicleEnumResponse?.fuelType ?? [],
                      selectedValue: controller.selectedFuelType.value,
                      title: AppStrings.fuelType.tr,
                      hintText: AppStrings.egPetrolDiesel.tr,
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
                      title: AppStrings.vehicleNumber.tr,
                      hintText: AppStrings.egWB5454.tr,
                      textEditController: controller.vehicleRegistrationNumberController,
                      validator: ValidationMethod.validateVehicleNumber,
                      isCapitalize: true,
                      maxLength: 10,
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    /// Vehicle Model
                    CommonTextField(
                      title: AppStrings.vehicleModelYearManufacturing.tr,
                      hintText: AppStrings.eg2020.tr,
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
                                  TextSpan(text: AppStrings.acceptAll.tr),
                                  TextSpan(
                                    text: AppStrings.termsConditions.tr,
                                    style: const TextStyle(color: AppColors.primaryColor),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.to(() => CommonWebView(
                                          urlLink: tncLink,
                                          urlTitle: AppStrings.termsConditions,
                                        ));
                                      },
                                  ),
                                  TextSpan(text: ' ${AppStrings.and.tr}\n'),
                                  TextSpan(
                                    text: AppStrings.privacyPolicy.tr,
                                    style: const TextStyle(color: AppColors.primaryColor),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.to(() => CommonWebView(
                                          urlLink: privacyLink,
                                          urlTitle: AppStrings.privacyPolicy,
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
                          : AppStrings.create.tr,
                      onTap: ()=> controller.ridersOnboardingVehicleInformationApi(
                          widget.screeName
                      ),
                      radius: 10.0,
                      bgColor: AppColors.primaryColor,
                      isLoading: controller.isRiderVehicleInformationLoading.value,
                    ),

                  ],
                ),
              ),
            ),
          ),
        ));
    if (isFromTab) return content;
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.vehicleInformation.tr,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              "${AppStrings.stepLabel.tr}3/3",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SafeArea(child: SingleChildScrollView(child: content)),
    );
  }
}
