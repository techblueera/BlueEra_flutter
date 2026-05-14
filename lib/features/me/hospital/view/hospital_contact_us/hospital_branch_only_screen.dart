import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_branch_contact_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalBranchOnlyScreen extends StatefulWidget {
  final SchoolContactUsData schoolContactUsData;

  const HospitalBranchOnlyScreen({
    super.key,
    required this.schoolContactUsData,
  });

  @override
  State<HospitalBranchOnlyScreen> createState() =>
      _HospitalBranchOnlyScreenState();
}

class _HospitalBranchOnlyScreenState extends State<HospitalBranchOnlyScreen> {
  final branchController = Get.find<HospitalBranchContactController>();

  final branchNameController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    branchController.isFormValid.value = false;
    final branch = widget.schoolContactUsData.branch;
    branchNameController.text = branch?.name ?? "";
    addressController.text = branch?.location?.name ?? "";
    websiteController.text = branch?.website ?? "";
    // The address field has no parent-facing onChange callback, so listen
    // on its controller to revalidate when the user types directly (the
    // other two fields already revalidate via their `onChange:` props).
    addressController.addListener(_runValidation);
  }

  @override
  void dispose() {
    branchNameController.dispose();
    websiteController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _runValidation() {
    branchController.branchValidateForm(
      branchName: branchNameController.text,
      branchWebsiteUrl: websiteController.text,
      branchLocation: addressController.text,
    );
  }

  Future<void> _handleSubmit() {
    return branchController.updateBranchContactController(
      reqBody: {
        "branch": {
          "name": branchNameController.text,
          "website": websiteController.text,
          "location": {
            "name": addressController.text,
            "type": "Point",
            "coordinates": [
              branchController.selectedLat,
              branchController.selectedLng,
            ],
          },
        },
      },
      branchId: widget.schoolContactUsData.id ?? "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.branch),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextField(
                textEditController: branchNameController,
                hintText: "E.g. DPS Dehradun",
                title: AppStrings.branchName,
                maxLength: 50,
                onChange: (_) => _runValidation(),
              ),
              const SizedBox(height: 12),
              HttpsTextField(
                controller: websiteController,
                hintText: "https://dpsdehradun.com",
                title: AppStrings.website,
                onChange: (_) => _runValidation(),
              ),
              const SizedBox(height: 12),
              CommonLocationSearchField(
                controller: addressController,
                title: AppStrings.location,
                isShowLeading: false,
                hintText: AppStrings.egLucknowGomtiNagar,
                onSelected: (placeId, lat, lng, address) {
                  addressController.text = address;
                  branchController.selectedLat = lat;
                  branchController.selectedLng = lng;
                  _runValidation();
                },
              ),
              const SizedBox(height: 24),
              Obx(() {
                final isValid = branchController.isFormValid.value;
                return CustomBtn(
                  onTap: isValid ? _handleSubmit : null,
                  title: AppStrings.submit,
                  isValidate: isValid,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
