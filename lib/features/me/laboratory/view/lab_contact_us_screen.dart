import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_contact_us_controller.dart';
import 'package:BlueEra/features/me/social/model/social_contact_us_res_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/info_banner.dart';
import 'package:BlueEra/widgets/section_icon_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabContactUsScreen extends StatefulWidget {
  const LabContactUsScreen({super.key, this.profile});

  final SocialContactUsData? profile;

  @override
  State<LabContactUsScreen> createState() => _LabContactUsScreenState();
}

class _LabContactUsScreenState extends State<LabContactUsScreen> {
  final controller = Get.find<LabContactUsController>();

  // Owned by the State and disposed exactly once. Do NOT re-create inside
  // build() — that would leak controllers every time the Rx data refreshes.
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await controller.fetchHomeData();
    if (!mounted) return;
    final data = controller.contactUsData.value?.data;
    if (data != null) {
      branchNameController.text = data.name ?? "";
      websiteController.text = data.websiteUrl ?? "";
      addressController.text = data.location?.name ?? "";
      emailController.text = data.email ?? "";
      phoneController.text = data.phoneNo ?? "";

      final coords = data.location?.coordinates;
      if (coords != null && coords.length >= 2) {
        controller.selectedLat = coords[0];
        controller.selectedLng = coords[1];
      }
    }
    _triggerValidation();
  }

  @override
  void dispose() {
    branchNameController.dispose();
    websiteController.dispose();
    addressController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _triggerValidation() {
    controller.validateForm(
      branchName: branchNameController.text,
      website: websiteController.text,
      address: addressController.text,
      email: emailController.text,
      phone: phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.profile != null;

    return Scaffold(
      appBar: CommonBackAppBar(
        title: isEdit ? AppStrings.update.tr : AppStrings.contactUs.tr,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size14),
        child: Column(
          children: [
            InfoBanner(
              icon: Icons.contact_mail_outlined,
              message: "Add your contact details so patients can reach you",
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Personal Info ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionIconHeader(
                      icon: Icons.person_outline,
                      title: AppStrings.labPersonalInfo.tr,
                      subtitle: AppStrings.labPersonalInfoSub.tr,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      textEditController: branchNameController,
                      hintText: AppStrings.labHintDspDehradun.tr,
                      title: AppStrings.fullName.tr,
                      onChange: (_) => _triggerValidation(),
                    ),
                    const SizedBox(height: 12),
                    HttpsTextField(
                      controller: websiteController,
                      hintText: AppStrings.labHintLabWebsite.tr,
                      title: AppStrings.website.tr,
                      onChange: (_) => _triggerValidation(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Contact Details ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionIconHeader(
                      icon: Icons.phone_outlined,
                      title: AppStrings.labContactDetailsTitle.tr,
                      subtitle: AppStrings.labContactDetailsSub.tr,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      textEditController: emailController,
                      hintText: AppStrings.labHintLabEmail.tr,
                      title: AppStrings.email.tr,
                      onChange: (_) => _triggerValidation(),
                    ),
                    const SizedBox(height: 12),
                    CommonTextField(
                      textEditController: phoneController,
                      hintText: AppStrings.labHintLabPhone.tr,
                      title: AppStrings.phoneNumber.tr,
                      maxLength: 10,
                      keyBoardType: TextInputType.phone,
                      onChange: (_) => _triggerValidation(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Location ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionIconHeader(
                      icon: Icons.location_on_outlined,
                      title: AppStrings.location,
                      subtitle: "Your laboratory address",
                    ),
                    const SizedBox(height: 16),
                    CommonLocationSearchField(
                      controller: addressController,
                      title: AppStrings.location,
                      isShowLeading: false,
                      onSelected: (placeId, lat, lng, address) async {
                        addressController.text = address;
                        try {
                          final detailsResponse = await PlaceRepo()
                              .getCompletePlaceDetails(placeId: placeId);
                          final detailsData = detailsResponse.response?.data;
                          final placeDetails =
                              PlaceDetailsResponse.fromJson(detailsData);
                          controller.selectedLat =
                              placeDetails.result?.geometry?.location?.lat ??
                                  0.0;
                          controller.selectedLng =
                              placeDetails.result?.geometry?.location?.lng ??
                                  0.0;
                        } catch (e) {
                          debugPrint("Error fetching place details: $e");
                        }
                        _triggerValidation();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Obx(() => CustomBtn(
                  // Show spinner during *submit*, not during initial data fetch.
                  isLoading: controller.isSaving.value,
                  onTap:
                      controller.isFormValid.value && !controller.isSaving.value
                          ? () => controller.submitBranchDetails(
                                branchName: branchNameController.text,
                                website: websiteController.text,
                                address: addressController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                              )
                          : null,
                  title: isEdit ? AppStrings.update.tr : AppStrings.submit.tr,
                  isValidate: controller.isFormValid.value,
                )),
            SizedBox(height: SizeConfig.size20),
          ],
        ),
      ),
    );
  }
}
