import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/deliver_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/deliver_partner/view/driving_verification_riding_screen.dart';
import 'package:BlueEra/features/common/deliver_partner/view/personal_identification_riding_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressLocationRidingScreen extends StatefulWidget {
  const AddressLocationRidingScreen({super.key});

  @override
  State<AddressLocationRidingScreen> createState() => _AddressLocationRidingScreenState();
}

class _AddressLocationRidingScreenState extends State<AddressLocationRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Address & Location",
        // onBackTap: onBackPressed,
        buildCustomWidget: ()=> Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              "Step-2/6",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: CustomFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonLocationSearchField(
                controller: controller.locationController,
                title: "Home Location",
                hintText: "E.g. Lucknow, Gomti Nagar...",
                onSelected: (lat, lng, address) {
                  print("Selected: $address → ($lat, $lng)");
                  controller.locationController.text = address;
                  controller.currentAddress.value = address;
                  controller.latitude = lat;
                  controller.longitude = lng;
                },
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.landmarkController,
                title: 'House No. and Land Mark ',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. Flat 21B, Lake View Apartment....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.pinCodeController,
                title: 'Pincode',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. 700045....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.cityController,
                title: 'City',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. Kolkata....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: controller.stateController,
                title: 'State',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                titleColor: AppColors.mainTextColor,
                hintText: "E.g. West Bengal....",
                keyBoardType: TextInputType.text,
                isValidate: true,
              ),

              SizedBox(height: SizeConfig.paddingM),

              CustomText(
                'Enable Live Location',
                fontSize: SizeConfig.small,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w400,
              ),
              SizedBox(height: SizeConfig.size10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    'Allow location access',
                    fontSize: SizeConfig.medium,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                  Obx(()=> CustomSwitch(
                    value: controller.enabledLiveLocation.value,
                    onChanged: (val) {
                      controller.enabledLiveLocation.value = !controller.enabledLiveLocation.value;
                    },
                    containerHeight: SizeConfig.size24,
                    containerWidth: SizeConfig.size50,
                    circleSize: SizeConfig.size18,
                  )),
                ],
              ),
              SizedBox(height: SizeConfig.paddingL),
              CustomBtn(
                title: 'Next',
                onTap: ()=> Get.to(()=> PersonalIdentificationRidingScreen()),
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
