import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalContactUsScreen extends StatefulWidget {
  const ProfessionalContactUsScreen({super.key, this.profile});

  final FoodContact? profile;

  @override
  State<ProfessionalContactUsScreen> createState() =>
      _ProfessionalContactUsScreenState();
}

class _ProfessionalContactUsScreenState
    extends State<ProfessionalContactUsScreen> {
  final controller = Get.put(ProfessionalsController());

  // Controllers
   TextEditingController branchNameController=TextEditingController();
   TextEditingController websiteController=TextEditingController();
   TextEditingController addressController=TextEditingController();
   TextEditingController emailController=TextEditingController();
   TextEditingController phoneController=TextEditingController();

  apiCalling() async {
    await controller.fetchHomeData();
  }

  @override
  void initState() {
    super.initState();
    apiCalling();
    // Initialize controllers with profile data if editing, otherwise empty

    // Run initial validation check after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerValidation());
  }

  @override
  void dispose() {
    // Clean up controllers
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
    // Determine if we are adding or editing for the UI
    final bool isEdit = widget.profile != null;

    return Scaffold(
      appBar: CommonBackAppBar(title: isEdit ? "Update Contact" : "Contact Us"),
      body: Obx(() {
        if (controller.contactUsData.value != null) {
          branchNameController = TextEditingController(
              text: controller.contactUsData.value?.data?.contactPerson ?? "");
          websiteController = TextEditingController(
              text: controller.contactUsData.value?.data?.website ?? "");
          addressController = TextEditingController(
              text: controller.contactUsData.value?.data?.address ?? "");
          emailController = TextEditingController(
              text: controller.contactUsData.value?.data?.email ?? "");
          phoneController = TextEditingController(
              text: controller.contactUsData.value?.data?.phone ?? "");

          // If editing, store existing lat/lng in controller
          if (controller.contactUsData.value?.data?.location != null) {
            controller.selectedLat =
                controller.contactUsData.value?.data?.location?.coordinates![0];
            controller.selectedLng =
                controller.contactUsData.value?.data?.location?.coordinates![1];
          }
        }
        return CommonCardWidget(
          padding: 0,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CommonTextField(
                  textEditController: branchNameController,
                  hintText: "E.g. DSP Dehradun",
                  title: "Contact Person Name",
                  onChange: (_) => _triggerValidation(),
                ),
                const SizedBox(height: 12),
                HttpsTextField(
                  controller: websiteController,
                  hintText: "https://dpsdehradun.com",
                  title: "Website URL",
                  onChange: (_) => _triggerValidation(),
                ),
                const SizedBox(height: 12),
                CommonLocationSearchField(
                  controller: addressController,
                  title: "Location",
                  isShowLeading: false,
                  onSelected: (placeId, lat, lng, address) async {
                    addressController.text = address;
                    // Fetch and auto-fill details
                    try {
                      final detailsResponse = await PlaceRepo()
                          .getCompletePlaceDetails(placeId: placeId);
                      final detailsData = detailsResponse.response?.data;
                      final placeDetails =
                          PlaceDetailsResponse.fromJson(detailsData);
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
                const SizedBox(height: 12),
                CommonTextField(
                  textEditController: emailController,
                  hintText: "dpsdehradun@gmail.com",
                  title: "Email Address",
                  onChange: (_) => _triggerValidation(),
                ),
                const SizedBox(height: 12),
                CommonTextField(
                  textEditController: phoneController,
                  hintText: "+91 1234567890",
                  title: "Phone Number",
                  maxLength: 10,
                  keyBoardType: TextInputType.phone,
                  onChange: (_) => _triggerValidation(),
                ),
                const SizedBox(height: 32),
                Obx(() => CustomBtn(
                      isLoading: controller.isLoading.value,
                      onTap: controller.isFormValid.value
                          ? () => controller.submitBranchDetails(
                                // id: widget.profile?.id, // Pass ID for editing
                                branchName: branchNameController.text,
                                website: websiteController.text,
                                address: addressController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                              )
                          : null,
                      title: isEdit ? "Update" : "Submit",
                      isValidate: controller.isFormValid.value,
                    )),
              ],
            ),
          ),
        );
      }),
    );
  }
}
