import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodContactUsScreen extends StatefulWidget {
  const FoodContactUsScreen({super.key, this.profile});
  final FoodContact? profile;

  @override
  State<FoodContactUsScreen> createState() => _FoodContactUsScreenState();
}

class _FoodContactUsScreenState extends State<FoodContactUsScreen> {
  final controller = Get.put(RestaurantController());

  // Controllers
  late TextEditingController branchNameController;
  late TextEditingController websiteController;
  late TextEditingController addressController;
  late TextEditingController titleController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with profile data if editing, otherwise empty
    branchNameController = TextEditingController(text: widget.profile?.name ?? "");
    websiteController = TextEditingController(text: widget.profile?.pageLink ?? "");
    addressController = TextEditingController(text: widget.profile?.location?.name ?? "");
    titleController = TextEditingController(text: widget.profile?.department ?? "");
    emailController = TextEditingController(text: widget.profile?.email ?? "");
    phoneController = TextEditingController(text: widget.profile?.phone ?? "");

    // If editing, store existing lat/lng in controller
    if (widget.profile?.location != null) {
      controller.selectedLat = widget.profile?.location?.coordinates![1]; // Assuming [lng, lat]
      controller.selectedLng = widget.profile?.location?.coordinates![0];
    }

    // Run initial validation check after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerValidation());
  }

  @override
  void dispose() {
    // Clean up controllers
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

  @override
  Widget build(BuildContext context) {
    // Determine if we are adding or editing for the UI
    final bool isEdit = widget.profile != null;

    return Scaffold(
      appBar: CommonBackAppBar(title: isEdit ? "Update Contact" : "Contact Us"),
      body: CommonCardWidget(
        padding: 0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CommonTextField(
                textEditController: branchNameController,
                hintText: "E.g. DPS Dehradun",
                title: "Branch Name",
                onChange: (_) => _triggerValidation(),
              ),
              const SizedBox(height: 12),
              HttpsTextField(
                controller: websiteController,
                hintText: "https://dpsdehradun.com",
                title: "Website URL",
                onChange: (_) => _triggerValidation(),
              ),
              const SizedBox(height: 24),
              CommonTextField(
                textEditController: titleController,
                hintText: "E.g. Admission Cell",
                title: "Department/Role",
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
                    final detailsResponse = await PlaceRepo().getCompletePlaceDetails(placeId: placeId);
                    final detailsData = detailsResponse.response?.data;
                    final placeDetails = PlaceDetailsResponse.fromJson(detailsData);
                    controller.selectedLat=placeDetails.result?.geometry?.location?.lat??0.0;
                    controller.selectedLng=placeDetails.result?.geometry?.location?.lng??0.0;
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
                  department: titleController.text,
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
      ),
    );
  }
}


