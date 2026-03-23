import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social_contact_us_controller.dart';
import 'package:BlueEra/features/me/social/model/social_contact_us_res_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialContactUsScreen extends StatefulWidget {
  const SocialContactUsScreen({super.key, this.profile});

  final SocialContactUsData? profile;

  @override
  State<SocialContactUsScreen> createState() =>
      _SocialContactUsScreenState();
}

class _SocialContactUsScreenState extends State<SocialContactUsScreen> {
  final controller = Get.put(SocialContactUsController());

  TextEditingController branchNameController = TextEditingController();
  TextEditingController websiteController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  apiCalling() async {
    await controller.fetchHomeData();
  }

  @override
  void initState() {
    super.initState();
    apiCalling();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _triggerValidation());
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
      appBar: CommonBackAppBar(title: AppStrings.contactUs),
      body: Obx(() {
        if (controller.contactUsData.value != null) {
          branchNameController = TextEditingController(
              text:
                  controller.contactUsData.value?.data?.name ?? "");
          websiteController = TextEditingController(
              text: controller.contactUsData.value?.data?.websiteUrl ??
                  "");
          addressController = TextEditingController(
              text: controller
                      .contactUsData.value?.data?.location?.name ??
                  "");
          emailController = TextEditingController(
              text:
                  controller.contactUsData.value?.data?.email ?? "");
          phoneController = TextEditingController(
              text: controller.contactUsData.value?.data?.phoneNo ??
                  "");

          if (controller.contactUsData.value?.data?.location !=
              null) {
            controller.selectedLat = controller
                .contactUsData.value?.data?.location?.coordinates![0];
            controller.selectedLng = controller
                .contactUsData.value?.data?.location?.coordinates![1];
          }
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size14),
          child: Column(
            children: [
              // --- Info Banner ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryColor
                          .withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.contact_mail_outlined,
                        color: AppColors.primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        "Add your contact details so people can reach you",
                        color: AppColors.primaryColor,
                        fontSize: SizeConfig.small,
                      ),
                    ),
                  ],
                ),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.person_outline,
                                color: AppColors.primaryColor,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          CustomText("Personal Info",
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CommonTextField(
                        textEditController: branchNameController,
                        hintText: "E.g. Rajesh Kr. Rajak",
                        title: AppStrings.fullName,
                        onChange: (_) => _triggerValidation(),
                      ),
                      const SizedBox(height: 12),
                      HttpsTextField(
                        controller: websiteController,
                        hintText: "https://yourwebsite.com",
                        title: AppStrings.website,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.phone_outlined,
                                color: AppColors.primaryColor,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          CustomText("Contact Details",
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CommonTextField(
                        textEditController: emailController,
                        hintText: "yourname@gmail.com",
                        title: AppStrings.email,
                        onChange: (_) => _triggerValidation(),
                      ),
                      const SizedBox(height: 12),
                      CommonTextField(
                        textEditController: phoneController,
                        hintText: "+91 1234567890",
                        title: AppStrings.phoneNumber,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.location_on_outlined,
                                color: AppColors.primaryColor,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          CustomText(AppStrings.location,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CommonLocationSearchField(
                        controller: addressController,
                        title: AppStrings.location,
                        isShowLeading: false,
                        onSelected:
                            (placeId, lat, lng, address) async {
                          addressController.text = address;
                          try {
                            final detailsResponse = await PlaceRepo()
                                .getCompletePlaceDetails(
                                    placeId: placeId);
                            final detailsData =
                                detailsResponse.response?.data;
                            final placeDetails =
                                PlaceDetailsResponse.fromJson(
                                    detailsData);
                            controller.selectedLat = placeDetails
                                    .result
                                    ?.geometry
                                    ?.location
                                    ?.lat ??
                                0.0;
                            controller.selectedLng = placeDetails
                                    .result
                                    ?.geometry
                                    ?.location
                                    ?.lng ??
                                0.0;
                          } catch (e) {
                            debugPrint(
                                "Error fetching place details: $e");
                          }
                          _triggerValidation();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Submit Button ---
              Obx(() => CustomBtn(
                    isLoading: controller.isLoading.value,
                    onTap: controller.isFormValid.value
                        ? () => controller.submitBranchDetails(
                              branchName: branchNameController.text,
                              website: websiteController.text,
                              address: addressController.text,
                              email: emailController.text,
                              phone: phoneController.text,
                            )
                        : null,
                    title: isEdit
                        ? AppStrings.update.tr
                        : AppStrings.submit.tr,
                    isValidate: controller.isFormValid.value,
                  )),
              SizedBox(height: SizeConfig.size20),
            ],
          ),
        );
      }),
    );
  }
}
