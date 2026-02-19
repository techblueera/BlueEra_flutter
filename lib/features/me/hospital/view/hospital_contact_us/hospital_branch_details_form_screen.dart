import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_branch_contact_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalBranchDetailsFormScreen extends StatefulWidget {
  @override
  _HospitalBranchDetailsFormScreenState createState() =>
      _HospitalBranchDetailsFormScreenState();
}

class _HospitalBranchDetailsFormScreenState extends State<HospitalBranchDetailsFormScreen> {
  // Initialize the specific controller
  final controller = Get.find<HospitalBranchContactController>();

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
              _buildHeader("Branch"),
              CommonTextField(
                textEditController: branchNameController,
                hintText: "E.g. DPS Dehradun",
                title: "Branch Name",
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              HttpsTextField(
                controller: websiteController,
                hintText: "https://dpsdehradun.com",
                title: "Website URL",
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonLocationSearchField(
                controller: addressController,
                title: "Location",
                onSelected: (placeId, lat, lng, address) {
                  addressController.text = address;
                  controller.selectedLat = lat;
                  controller.selectedLng = lng;
                  _triggerValidation();
                },
              ),

              SizedBox(height: 24),
              _buildHeader("Department"),

              CommonTextField(
                textEditController: titleController,
                hintText: "E.g. Admission Cell",
                title: "Department/Role",
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                hintText: "dpsdehradun@gmail.com",
                title: "Email Address",
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: "+91 1234567890",
                title: "Phone Number",
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
                    title: "Submit",
                    isValidate: controller.isFormValid.value,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomText(
          text,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
      ),
    );
  }
}
