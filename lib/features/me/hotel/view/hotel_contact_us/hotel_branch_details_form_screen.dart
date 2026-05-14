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

/// Form for creating a new reception/branch contact: website, address,
/// email and phone. The selected location's lat/lng are stashed on the
/// controller via [CommonLocationSearchField.onSelected].
class HotelBranchDetailsFormScreen extends StatefulWidget {
  const HotelBranchDetailsFormScreen({super.key});

  @override
  State<HotelBranchDetailsFormScreen> createState() =>
      _HotelBranchDetailsFormScreenState();
}

class _HotelBranchDetailsFormScreenState
    extends State<HotelBranchDetailsFormScreen> {
  final controller = Get.find<HotelBranchContactController>();

  final websiteController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    websiteController.dispose();
    addressController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  /// Pushes the current field values into the controller's validator so the
  /// `Submit` button enables/disables in real time.
  void _triggerValidation([_]) {
    controller.validateForm(
      branchName: '',
      website: websiteController.text,
      address: addressController.text,
      email: emailController.text,
      phone: phoneController.text,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return AppStrings.required.tr;
    if (!value.trim().toLowerCase().endsWith("@gmail.com")) {
      return AppStrings.onlyGmailAllowed.tr;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return AppStrings.required.tr;
    if (value.length != 10) return AppStrings.enterValidPhoneNumber.tr;
    final isRepetitive = value.split('').every((c) => c == value[0]);
    if (isRepetitive) return AppStrings.enterValidPhoneNumber.tr;
    return null;
  }

  Future<void> _onSubmit() {
    return controller.submitBranchDetails(
      website: websiteController.text,
      address: addressController.text,
      email: emailController.text,
      phone: phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.contactUs.tr),
      body: CommonCardWidget(
        padding: 0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              HttpsTextField(
                controller: websiteController,
                hintText: AppStrings.hotelWebsiteHint.tr,
                title: AppStrings.website.tr,
                isUrlValidate: true,
                onChange: _triggerValidation,
              ),
              const SizedBox(height: 12),
              CommonLocationSearchField(
                controller: addressController,
                title: AppStrings.location.tr,
                isShowLeading: false,
                onSelected: (placeId, lat, lng, address) {
                  addressController.text = address;
                  controller.selectedLat = lat;
                  controller.selectedLng = lng;
                  _triggerValidation();
                },
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                hintText: AppStrings.hotelEmailExampleHint.tr,
                title: AppStrings.email.tr,
                validator: _validateEmail,
                onChange: _triggerValidation,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: AppStrings.hotelPhoneExampleHint.tr,
                title: AppStrings.phoneNumber.tr,
                keyBoardType: TextInputType.number,
                regularExpression: r'[0-9]',
                maxLength: 10,
                validator: _validatePhone,
                onChange: _triggerValidation,
              ),
              const SizedBox(height: 32),
              Obx(
                () => CustomBtn(
                  isLoading: controller.isLoading.value,
                  onTap: controller.isFormValid.value ? _onSubmit : null,
                  title: AppStrings.submit.tr,
                  isValidate: controller.isFormValid.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
