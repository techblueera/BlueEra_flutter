import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_branch_contact_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelBranchDetailsFormScreen extends StatefulWidget {
  @override
  _HotelBranchDetailsFormScreenState createState() =>
      _HotelBranchDetailsFormScreenState();
}

class _HotelBranchDetailsFormScreenState extends State<HotelBranchDetailsFormScreen> {
  // Initialize the specific controller
  final controller = Get.find<HotelBranchContactController>();

  final branchNameController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();
  final titleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  void _triggerValidation() {
    controller.validateForm(
      branchName: branchNameController.text,
      website: websiteController.text,
      address: addressController.text,
      department: titleController.text,
      email: emailController.text,
      phone: phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Contact Us"),
      body: CommonCardWidget(
        padding: 0,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              HttpsTextField(
                controller: websiteController,
                hintText: "https://yourwebsite.com",
                title: AppStrings.website,
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonLocationSearchField(
                controller: addressController,
                title:  AppStrings.location.tr,
                isShowLeading: false,
                onSelected: (placeId, lat, lng, address) {
                  addressController.text = address;
                  controller.selectedLat = lat;
                  controller.selectedLng = lng;
                  _triggerValidation();
                },
              ),
              SizedBox(height: 12),

              CommonTextField(
                textEditController: emailController,
                hintText: "dpsdehradun@gmail.com",
                title: AppStrings.email,
                onChange: (_) => _triggerValidation(),
              ),

              SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: "+91 1234567890",
                title:  AppStrings.phoneNumber,
                maxLength: 10,
                onChange: (_) => _triggerValidation(),
              ),

              SizedBox(height: 32),

              // Reactive Submit Button
              Obx(() => CustomBtn(
                    isLoading: controller.isLoading.value,
                    onTap: controller.isFormValid.value
                        ? () => controller.submitBranchDetails(
                              branchName: branchNameController.text,
                              website: websiteController.text,
                              address: addressController.text,
                              department: titleController.text,
                              email: emailController.text,
                              phone: phoneController.text,
                            )
                        : null, // Button disabled if form invalid
                    title:  AppStrings.submit,
                    isValidate: controller.isFormValid.value,
                  )),
            ],
          ),
        ),
      ),
    );
  }

}
