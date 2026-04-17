import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_branch_contact_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HospitalBranchDetailsFormScreen extends StatefulWidget {
  @override
  _HospitalBranchDetailsFormScreenState createState() =>
      _HospitalBranchDetailsFormScreenState();
}

class _HospitalBranchDetailsFormScreenState
    extends State<HospitalBranchDetailsFormScreen> {
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

  void _handleSubmit() {
    _triggerValidation();
    if (!controller.isFormValid.value) {
      final error = controller.getFirstError();
      if (error != null) {
        commonSnackBar(message: error);
      }
      return;
    }
    controller.submitBranchDetails(
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
      appBar: CommonBackAppBar(title: AppStrings.contactUs),
      body: CommonCardWidget(
        padding: 0,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Obx(() => Column(
            children: [
              _buildHeader(AppStrings.branch),
              CommonTextField(
                textEditController: branchNameController,
                hintText: "E.g. DPS Dehradun",
                title: AppStrings.branchName,
                onChange: (_) => _triggerValidation(),
              ),
              if (controller.branchNameError.value.isNotEmpty)
                _buildErrorText(controller.branchNameError.value),
              SizedBox(height: 12),
              HttpsTextField(
                controller: websiteController,
                hintText: "https://dpsdehradun.com",
                title: AppStrings.website,
                onChange: (_) => _triggerValidation(),
              ),
              if (controller.websiteError.value.isNotEmpty)
                _buildErrorText(controller.websiteError.value),
              SizedBox(height: 12),
              CommonLocationSearchField(
                controller: addressController,
                title: AppStrings.location,
                onSelected: (placeId, lat, lng, address) {
                  addressController.text = address;
                  controller.selectedLat = lat;
                  controller.selectedLng = lng;
                  _triggerValidation();
                },
              ),
              if (controller.addressError.value.isNotEmpty)
                _buildErrorText(controller.addressError.value),

              SizedBox(height: 24),
              _buildHeader(AppStrings.department),

              CommonTextField(
                textEditController: titleController,
                hintText: "E.g. Admission Cell",
                title: AppStrings.department,
                onChange: (_) => _triggerValidation(),
              ),
              if (controller.departmentError.value.isNotEmpty)
                _buildErrorText(controller.departmentError.value),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                hintText: "example@gmail.com",
                title: AppStrings.enterEmailAddress,
                keyBoardType: TextInputType.emailAddress,
                onChange: (_) => _triggerValidation(),
              ),
              if (controller.emailError.value.isNotEmpty)
                _buildErrorText(controller.emailError.value),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: "1234567890",
                title: AppStrings.phoneNumber,
                maxLength: 10,
                keyBoardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChange: (_) => _triggerValidation(),
              ),
              if (controller.phoneError.value.isNotEmpty)
                _buildErrorText(controller.phoneError.value),

              SizedBox(height: 32),

              // Submit Button - always clickable for validation feedback
              CustomBtn(
                isLoading: controller.isLoading.value,
                onTap: () => _handleSubmit(),
                title: AppStrings.submit,
                isValidate: controller.isFormValid.value,
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomText(
          error,
          fontSize: 12,
          color: Colors.red,
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

