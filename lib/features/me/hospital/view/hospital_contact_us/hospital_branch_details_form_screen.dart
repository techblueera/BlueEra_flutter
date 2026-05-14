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
  const HospitalBranchDetailsFormScreen({super.key});

  @override
  State<HospitalBranchDetailsFormScreen> createState() =>
      _HospitalBranchDetailsFormScreenState();
}

class _HospitalBranchDetailsFormScreenState
    extends State<HospitalBranchDetailsFormScreen> {
  final controller = Get.find<HospitalBranchContactController>();

  final branchNameController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();
  final titleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    branchNameController.dispose();
    websiteController.dispose();
    addressController.dispose();
    titleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

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
          padding: const EdgeInsets.all(16),
          child: Obx(
            () => Column(
              children: [
                _buildHeader(AppStrings.branch),
                _fieldWithError(
                  field: _textField(
                    textController: branchNameController,
                    hint: "E.g. DPS Dehradun",
                    title: AppStrings.branchName,
                  ),
                  errorRx: controller.branchNameError,
                  gap: 12,
                ),
                _fieldWithError(
                  field: HttpsTextField(
                    controller: websiteController,
                    hintText: "https://dpsdehradun.com",
                    title: AppStrings.website,
                    onChange: (_) => _triggerValidation(),
                  ),
                  errorRx: controller.websiteError,
                  gap: 12,
                ),
                _fieldWithError(
                  field: CommonLocationSearchField(
                    controller: addressController,
                    title: AppStrings.location,
                    onSelected: (placeId, lat, lng, address) {
                      addressController.text = address;
                      controller.selectedLat = lat;
                      controller.selectedLng = lng;
                      _triggerValidation();
                    },
                  ),
                  errorRx: controller.addressError,
                  gap: 24,
                ),
                _buildHeader(AppStrings.department),
                _fieldWithError(
                  field: _textField(
                    textController: titleController,
                    hint: "E.g. Admission Cell",
                    title: AppStrings.department,
                  ),
                  errorRx: controller.departmentError,
                  gap: 12,
                ),
                _fieldWithError(
                  field: _textField(
                    textController: emailController,
                    hint: "example@gmail.com",
                    title: AppStrings.enterEmailAddress,
                    keyBoardType: TextInputType.emailAddress,
                  ),
                  errorRx: controller.emailError,
                  gap: 12,
                ),
                _fieldWithError(
                  field: _textField(
                    textController: phoneController,
                    hint: "1234567890",
                    title: AppStrings.phoneNumber,
                    keyBoardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  errorRx: controller.phoneError,
                  gap: 32,
                ),
                // Submit Button - always clickable for validation feedback
                CustomBtn(
                  isLoading: controller.isLoading.value,
                  onTap: _handleSubmit,
                  title: AppStrings.submit,
                  isValidate: controller.isFormValid.value,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController textController,
    required String hint,
    required String title,
    TextInputType? keyBoardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return CommonTextField(
      textEditController: textController,
      hintText: hint,
      title: title,
      keyBoardType: keyBoardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChange: (_) => _triggerValidation(),
    );
  }

  Widget _fieldWithError({
    required Widget field,
    required RxString errorRx,
    required double gap,
  }) {
    return Column(
      children: [
        field,
        if (errorRx.value.isNotEmpty) _buildErrorText(errorRx.value),
        SizedBox(height: gap),
      ],
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
