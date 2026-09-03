import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_branch_contact_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherBranchDetailsFormScreen extends StatefulWidget {
  @override
  _OtherBranchDetailsFormScreenState createState() =>
      _OtherBranchDetailsFormScreenState();
}

class _OtherBranchDetailsFormScreenState
    extends State<OtherBranchDetailsFormScreen> {
  // Initialize the specific controller
  final controller = Get.find<AutomotiveBranchContactController>();

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
      appBar: CommonBackAppBar(title: AppStrings.contactUs.tr),
      body: CommonCardWidget(
        padding: 0,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(AppStrings.branch.tr),
              CommonTextField(
                textEditController: branchNameController,
                hintText: AppStrings.hotelHintBranchName.tr,
                title: AppStrings.otherBranchNameTitle.tr,
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              HttpsTextField(
                controller: websiteController,
                hintText: AppStrings.hotelHintBranchUrl.tr,
                title: AppStrings.otherWebsiteUrlTitle.tr,
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonLocationSearchField(
                controller: addressController,
                title: AppStrings.location.tr,
                onSelected: (placeId, lat, lng, address) async {
                  addressController.text = address;

                  try {
                    final detailsResponse = await PlaceRepo()
                        .getCompletePlaceDetails(placeId: placeId);
                    final detailsData = detailsResponse.response?.data;
                    final placeDetails =
                        PlaceDetailsResponse.fromJson(detailsData);
                    logs("detailsData=== ${detailsData}");
                    logs(
                        "placeDetails.result?.geometry?.location?.lat??0.0=== ${placeDetails.result?.geometry?.location?.lat ?? 0.0}");
                    logs(
                        "placeDetails.result?.geometry?.location?.lng??0.0=== ${placeDetails.result?.geometry?.location?.lng ?? 0.0}");
                    controller.selectedLat =
                        placeDetails.result?.geometry?.location?.lat ?? 0.0;
                    controller.selectedLng =
                        placeDetails.result?.geometry?.location?.lng ?? 0.0;
                  } catch (e) {
                    print("Error fetching place details: $e");
                  }

                  _triggerValidation();
                },
              ),

              SizedBox(height: 24),
              _buildHeader(AppStrings.department.tr),

              CommonTextField(
                textEditController: titleController,
                hintText: AppStrings.otherHintAdmissionCell.tr,
                title: AppStrings.otherDepartmentRoleTitle.tr,
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                hintText: AppStrings.hotelEmailExampleHint.tr,
                title: AppStrings.otherEmailAddressTitle.tr,
                onChange: (_) => _triggerValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: AppStrings.hotelPhoneExampleHint.tr,
                title: AppStrings.phoneNumber.tr,
                maxLength: 10,
                onChange: (_) => _triggerValidation(),
              ),

              SizedBox(height: 32),

              // Reactive Submit Button
              Obx(() => CustomBtn(
                  isLoading: controller.isLoading.value,
                  onTap: /*controller.isFormValid.value
                        ?*/
                      () => controller.submitBranchDetails(
                            branchName: branchNameController.text,
                            website: websiteController.text,
                            address: addressController.text,
                            department: titleController.text,
                            email: emailController.text,
                            phone: phoneController.text,
                          ),
                  // : null, // Button disabled if form invalid
                  title: AppStrings.submit.tr,
                  isValidate: true)),
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
